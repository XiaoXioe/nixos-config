"""Nix utilities: store path resolution, channel normalization, evaluation, in-place pin modification, and discovery."""
import json
import os
from pathlib import Path
import re
import subprocess
import sys
from typing import Any, Dict, List, Optional, Tuple


def resolve_channel_input(channel_or_input: Optional[str]) -> str:
    """Normalize user channel shorthand (e.g. 'unstable', '26.05', '25.11') to full flake input URL."""
    if not channel_or_input:
        return "nixpkgs"

    val = channel_or_input.strip()

    # Direct flake URLs or references with : or /
    if ":" in val or "/" in val:
        return val

    mapping = {
        "unstable": "github:NixOS/nixpkgs/nixos-unstable",
        "nixos-unstable": "github:NixOS/nixpkgs/nixos-unstable",
        "nixpkgs-unstable": "github:NixOS/nixpkgs/nixpkgs-unstable",
        "pkgs-unstable": "github:NixOS/nixpkgs/nixpkgs-unstable",
        "master": "github:NixOS/nixpkgs/master",
        "staging": "github:NixOS/nixpkgs/staging",
        "staging-next": "github:NixOS/nixpkgs/staging-next",
    }

    if val.lower() in mapping:
        return mapping[val.lower()]

    # Format XX.YY (e.g. 26.05, 25.11, 25.05, 24.11, 24.05, 23.11)
    if re.match(r"^\d{2}\.\d{2}$", val):
        return f"github:NixOS/nixpkgs/nixos-{val}"

    # Format nixos-XX.YY
    if re.match(r"^nixos-\d{2}\.\d{2}$", val):
        return f"github:NixOS/nixpkgs/{val}"

    return val


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

    # Search standard NixOS config locations
    home = Path.home()
    candidates = [
        home / "nixos-config" / "modules" / "_lib" / "cache-pins.nix",
        home / ".config" / "nixos" / "modules" / "_lib" / "cache-pins.nix",
        Path("/etc/nixos/modules/_lib/cache-pins.nix"),
    ]
    for candidate in candidates:
        if candidate.is_file():
            return candidate.resolve()

    return None


def is_path_in_nix_store(store_path: str) -> bool:
    """Check if a store path exists and is valid in local /nix/store."""
    if not store_path.startswith("/nix/store/"):
        return False
    if not os.path.exists(store_path):
        return False
    try:
        res = subprocess.run(
            ["nix-store", "--check-validity", store_path],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=5,
        )
        return res.returncode == 0
    except Exception:
        return os.path.exists(store_path)


def extract_version_from_store_path(store_path: str) -> str:
    """Extract version number from store path basename."""
    basename = os.path.basename(store_path)
    match = re.search(r"(?<=-)\d[\d.a-zA-Z_+-]*", basename)
    if match:
        return match.group(0)
    return "unknown"


def eval_nix_raw(expr: str, flake_url: Optional[str] = None) -> Optional[str]:
    """Evaluate a Nix expression and return raw stdout."""
    try:
        cmd = ["nix", "eval", "--raw"]
        if flake_url:
            cmd.append(f"{flake_url}#{expr}")
        else:
            cmd.extend(["--impure", "--expr", expr])
        res = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
        if res.returncode == 0:
            out = res.stdout.strip()
            if out and out != "null" and out != '""':
                return out
    except Exception:
        pass
    return None


def resolve_target_to_store_path(
    target: str,
    nixpkgs_input: str = "nixpkgs",
    pins_file: Optional[Path] = None,
) -> Tuple[str, str, Optional[str]]:
    """Resolve a user target to (store_path, version, main_program)."""
    # 1. Direct store path: /nix/store/<hash>-<name>
    if re.match(r"^/nix/store/[a-z0-9]{32}-.+", target):
        version = extract_version_from_store_path(target)
        return target, version, None

    # 2. Explicit pkgs. prefix or custom flake input
    if target.startswith("pkgs.") or (nixpkgs_input and nixpkgs_input != "nixpkgs"):
        attr = target if target.startswith("pkgs.") else f"pkgs.{target}"
        store_path = eval_nix_raw(f"{attr}.outPath", nixpkgs_input)
        if not store_path:
            # Try without pkgs. prefix
            store_path = eval_nix_raw(f"{target}.outPath", nixpkgs_input)

        if store_path and store_path.startswith("/nix/store/"):
            main_prog = eval_nix_raw(f"{attr}.meta.mainProgram", nixpkgs_input) or eval_nix_raw(
                f"{target}.meta.mainProgram", nixpkgs_input
            )
            version = extract_version_from_store_path(store_path)
            return store_path, version, main_prog
        elif target.startswith("pkgs."):
            raise RuntimeError(f"Gagal mengevaluasi {nixpkgs_input}#{target}")

    # 3. Check cache-pins.nix if available
    if pins_file and pins_file.is_file():
        key_orig = target
        key_underscore = target.replace("-", "_")
        key_dash = target.replace("_", "-")
        expr = f"""
        let pins = import {pins_file};
        in pins.{key_orig}.storePath or pins.{key_underscore}.storePath or pins.{key_dash}.storePath or ""
        """
        resolved = eval_nix_raw(expr)
        if resolved and resolved.startswith("/nix/store/"):
            expr_mp = f"""
            let pins = import {pins_file};
            in pins.{key_orig}.mainProgram or pins.{key_underscore}.mainProgram or pins.{key_dash}.mainProgram or ""
            """
            main_program = eval_nix_raw(expr_mp)
            version = extract_version_from_store_path(resolved)
            return resolved, version, main_program

    # 4. Fallback to nix eval nixpkgs#pkgs.<target>.outPath or nixpkgs#<target>.outPath
    attr_try1 = f"pkgs.{target}"
    store_path = eval_nix_raw(f"{attr_try1}.outPath", "nixpkgs")
    if store_path and store_path.startswith("/nix/store/"):
        main_program = eval_nix_raw(f"{attr_try1}.meta.mainProgram", "nixpkgs")
        version = extract_version_from_store_path(store_path)
        return store_path, version, main_program

    store_path = eval_nix_raw(f"{target}.outPath", "nixpkgs")
    if store_path and store_path.startswith("/nix/store/"):
        main_program = eval_nix_raw(f"{target}.meta.mainProgram", "nixpkgs")
        version = extract_version_from_store_path(store_path)
        return store_path, version, main_program

    raise RuntimeError(
        f"Tidak dapat menemukan store path untuk '{target}'. "
        "Pastikan nama valid atau terdaftar di modules/_lib/cache-pins.nix."
    )


def load_cache_pins(pins_file: Path) -> Dict[str, Dict[str, Any]]:
    """Load all pin entries from cache-pins.nix as JSON dict."""
    expr = f"import {pins_file}"
    try:
        res = subprocess.run(
            ["nix", "eval", "--json", "--impure", "--expr", expr],
            capture_output=True,
            text=True,
            timeout=30,
        )
        if res.returncode == 0:
            return json.loads(res.stdout)
    except Exception as e:
        print(f"Error loading {pins_file}: {e}", file=sys.stderr)
    return {}


def get_all_pin_keys(pins_file: Path) -> List[str]:
    """Get sorted list of all pin keys in cache-pins.nix."""
    data = load_cache_pins(pins_file)
    return sorted(list(data.keys()))


def write_or_update_pin(pins_file: Path, target_key: str, snippet: str) -> bool:
    """Write or update a pin entry in cache-pins.nix, then format with nixfmt."""
    if not pins_file.is_file():
        raise FileNotFoundError(f"Berkas pin tidak ditemukan: {pins_file}")

    content = pins_file.read_text(encoding="utf-8")
    clean_key = re.sub(r"[^a-zA-Z0-9_]", "_", target_key.replace("pkgs.", ""))

    # Regex matching existing block with comments
    pattern = re.compile(
        rf"(?m)((?:^[ \t]*#[^\n]*\n)*^[ \t]*{re.escape(clean_key)}\s*=\s*\{{.*?\n[ \t]*\}};\n?)",
        re.DOTALL,
    )
    match = pattern.search(content)

    formatted_snippet = "\n" + snippet.strip() + "\n"

    if match:
        new_content = content[: match.start()] + formatted_snippet + content[match.end() :]
    else:
        footer_comment_match = re.search(r"(?m)^[ \t]*#[ \t]*──[ \t]*Tambah entri lain", content)
        if footer_comment_match:
            insert_pos = footer_comment_match.start()
            new_content = content[:insert_pos] + formatted_snippet + "\n" + content[insert_pos:]
        else:
            last_brace_idx = content.rfind("}")
            if last_brace_idx != -1:
                new_content = content[:last_brace_idx] + formatted_snippet + content[last_brace_idx:]
            else:
                new_content = content + "\n" + formatted_snippet

    pins_file.write_text(new_content, encoding="utf-8")

    # Run nixfmt if available
    try:
        subprocess.run(["nixfmt", str(pins_file)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass

    return True
