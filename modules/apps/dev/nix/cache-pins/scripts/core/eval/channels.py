"""Channel resolution, flake directory discovery, and environment configuration."""
import json
import os
from pathlib import Path
import re
from typing import Dict, Optional


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


def find_cache_pins_file(custom_path: Optional[str] = None) -> Optional[Path]:
    """Dynamically discover modules/_lib/cache-pins.nix."""
    if custom_path:
        p = Path(custom_path)
        if p.is_file():
            return p.resolve()
        return None

    # Check environment variable
    env_path = os.environ.get("PINS_FILE")
    if env_path and Path(env_path).is_file():
        return Path(env_path).resolve()

    # Search upwards from current working directory
    cwd = Path.cwd()
    for parent in [cwd] + list(cwd.parents):
        candidate = parent / "modules" / "_lib" / "cache-pins.nix"
        if candidate.is_file():
            return candidate.resolve()

    # Search standard configuration paths
    home = Path.home()
    candidates = [
        home / "nixos-config" / "modules" / "_lib" / "cache-pins.nix",
        home / ".config" / "nixos" / "modules" / "_lib" / "cache-pins.nix",
        Path("/etc/nixos/modules/_lib/cache-pins.nix"),
    ]
    for c in candidates:
        if c.is_file():
            return c.resolve()

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

    mapping = {
        "nixpkgs": "nixpkgs",
        "unstable": "github:NixOS/nixpkgs/nixos-unstable",
        "nixos-unstable": "github:NixOS/nixpkgs/nixos-unstable",
        "nixpkgs-unstable": "github:NixOS/nixpkgs/nixpkgs-unstable",
        "pkgs-unstable": "github:NixOS/nixpkgs/nixpkgs-unstable",
        "master": "github:NixOS/nixpkgs/master",
        "staging": "github:NixOS/nixpkgs/staging",
        "staging-next": "github:NixOS/nixpkgs/staging-next",
        "cachyos": "github:xddxdd/nix-cachyos-kernel/release",
        "nix-cachyos-kernel": "github:xddxdd/nix-cachyos-kernel/release",
    }

    if val.lower() in mapping:
        return mapping[val.lower()]

    # Format XX.YY, nixos-XX.YY, nixpkgs-XX.YY (e.g. 26.05, nixpkgs-25.11, nixos-24.05)
    m = re.match(r"^(?:nixos-|nixpkgs-)?(\d{2}\.\d{2}(?:-small|-darwin)?)$", val, re.IGNORECASE)
    if m:
        sub = m.group(1)
        if sub.endswith("-darwin"):
            return f"github:NixOS/nixpkgs/nixpkgs-{sub}"
        return f"github:NixOS/nixpkgs/nixos-{sub}"

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
    if "nixos-unstable" in s or s in ("unstable", "nixpkgs-unstable"):
        return "unstable"
    match_ver = re.search(r"nixos-(\d{2}\.\d{2})", s)
    if match_ver:
        return match_ver.group(1)
    if re.match(r"^\d{2}\.\d{2}$", s):
        return s
    if s == "nixpkgs":
        return "nixpkgs"
    return s
