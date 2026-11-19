"""Channel resolution, flake directory discovery, and environment configuration."""
import json
import os
from pathlib import Path
import re
from typing import Dict, Optional

from core.platform import get_current_system


def find_flake_dir() -> Optional[Path]:
    """Find root directory containing flake.nix / flake.lock."""
    cwd = Path.cwd()
    for parent in [cwd] + list(cwd.parents):
        if (parent / "flake.nix").is_file():
            return parent.resolve()
    home = Path.home()
    for candidate in [
        home / "nixos-config",
        home / ".config" / "nixos",
        Path("/etc/nixos"),
    ]:
        if (candidate / "flake.nix").is_file():
            return candidate.resolve()
    return None


def get_nix_env() -> Dict[str, str]:
    """Return environment dictionary with unfree and insecure evaluation enabled."""
    env = os.environ.copy()
    env["NIXPKGS_ALLOW_UNFREE"] = "1"
    env["NIXPKGS_ALLOW_INSECURE"] = "1"
    env["NIXPKGS_ALLOW_BROKEN"] = "1"
    return env


def resolve_channel_input(channel_or_input: Optional[str]) -> str:
    """Normalize user channel shorthand or flake input name to full flake input URL."""
    if not channel_or_input:
        return "nixpkgs"

    val = channel_or_input.strip()

    # Local filesystem path
    if val.startswith("/") or val.startswith("./") or val.startswith("../"):
        return f"path:{Path(val).resolve()}"

    # Direct flake URLs or references with : or /
    if ":" in val or "/" in val:
        return val

    # Check flake.lock for matching input name via root inputs mapping first
    flake_dir = find_flake_dir()
    root_inputs = {}
    nodes = {}
    if flake_dir:
        flake_lock = flake_dir / "flake.lock"
        if flake_lock.is_file():
            try:
                data = json.loads(flake_lock.read_text(encoding="utf-8"))
                nodes = data.get("nodes", {})
                root_node = nodes.get(data.get("root", "root"), {})
                root_inputs = root_node.get("inputs", {})
            except Exception:
                pass

    if val in root_inputs:
        return val

    if val.lower() in ("unstable", "nixos-unstable", "nixpkgs-unstable", "pkgs-unstable") and "nixpkgs-unstable" in root_inputs:
        return "nixpkgs-unstable"

    mapping = {
        "nixpkgs": "nixpkgs",
        "unstable": "git+https://github.com/NixOS/nixpkgs?shallow=1&ref=nixos-unstable",
        "nixos-unstable": "git+https://github.com/NixOS/nixpkgs?shallow=1&ref=nixos-unstable",
        "nixpkgs-unstable": "git+https://github.com/NixOS/nixpkgs?shallow=1&ref=nixpkgs-unstable",
        "pkgs-unstable": "git+https://github.com/NixOS/nixpkgs?shallow=1&ref=nixpkgs-unstable",
        "master": "git+https://github.com/NixOS/nixpkgs?shallow=1&ref=master",
        "staging": "git+https://github.com/NixOS/nixpkgs?shallow=1&ref=staging",
        "staging-next": "git+https://github.com/NixOS/nixpkgs?shallow=1&ref=staging-next",
        "cachyos": "github:xddxdd/nix-cachyos-kernel/release",
        "nix-cachyos-kernel": "github:xddxdd/nix-cachyos-kernel/release",
    }

    if val.lower() in mapping:
        return mapping[val.lower()]

    # Format XX.YY, nixos-XX.YY, nixpkgs-XX.YY (e.g. 26.05, nixpkgs-25.11, nixos-24.05)
    m = re.match(r"^(?:nixos-|nixpkgs-)?(\d{2}\.\d{2}(?:-small|-darwin)?)$", val, re.IGNORECASE)
    if m:
        sub = m.group(1)
        ref_branch = f"nixpkgs-{sub}" if sub.endswith("-darwin") else f"nixos-{sub}"
        return f"git+https://github.com/NixOS/nixpkgs?shallow=1&ref={ref_branch}"

    # Check flake.lock for matching input name via root inputs mapping
    flake_dir = find_flake_dir()
    if flake_dir:
        flake_lock = flake_dir / "flake.lock"
        if flake_lock.is_file():
            try:
                data = json.loads(flake_lock.read_text(encoding="utf-8"))
                nodes = data.get("nodes", {})
                root_node = nodes.get(data.get("root", "root"), {})
                root_inputs = root_node.get("inputs", {})

                if val in root_inputs:
                    return val

                target_id = root_inputs.get(val, val)
                if target_id in nodes:
                    node_data = nodes[target_id]
                    orig = node_data.get("original", {})
                    t = orig.get("type")
                    if t == "github" and orig.get("owner") and orig.get("repo"):
                        ref = f"/{orig.get('ref')}" if orig.get("ref") else ""
                        return f"github:{orig.get('owner')}/{orig.get('repo')}{ref}"
                    elif t == "gitlab" and orig.get("owner") and orig.get("repo"):
                        ref = f"/{orig.get('ref')}" if orig.get("ref") else ""
                        return f"gitlab:{orig.get('owner')}/{orig.get('repo')}{ref}"
                    elif t == "git" and orig.get("url"):
                        url = orig.get("url", "")
                        ref = orig.get("ref", "")
                        if "github.com/" in url:
                            parts = url.split("github.com/")[-1].rstrip("/").replace(".git", "").split("/")
                            if len(parts) >= 2:
                                ref_part = f"/{ref}" if ref else ""
                                return f"github:{parts[0]}/{parts[1]}{ref_part}"
                        ref_suffix = f"?ref={ref}" if ref else ""
                        return f"git+{url}{ref_suffix}"
                    elif orig.get("url"):
                        return orig.get("url")
            except Exception:
                pass

    return val


def normalize_channel_name(source_input: str) -> str:
    """Extract clean shorthand channel name from source input URL."""
    if not source_input:
        return "nixpkgs"
    s = source_input.strip()
    if "nixos-unstable" in s or s in ("unstable", "nixpkgs-unstable") or "ref=nixos-unstable" in s or "ref=nixpkgs-unstable" in s:
        return "unstable"
    match_ver = re.search(r"nixos-(\d{2}\.\d{2})", s)
    if match_ver:
        return match_ver.group(1)
    if re.match(r"^\d{2}\.\d{2}$", s):
        return s
    if s == "nixpkgs":
        return "nixpkgs"
    return s
