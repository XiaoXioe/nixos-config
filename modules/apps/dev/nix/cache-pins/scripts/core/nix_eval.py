"""Nix evaluation utilities: store path resolution, channel normalization, and discovery."""
import json
import os
from pathlib import Path
import re
import subprocess
import sys
from typing import Any, Dict, Optional, Tuple


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

    # Format XX.YY (e.g. 26.05, 25.11, 25.05, 24.11, 24.05, 23.11)
    if re.match(r"^\d{2}\.\d{2}$", val):
        return f"github:NixOS/nixpkgs/nixos-{val}"

    # Format nixos-XX.YY
    if re.match(r"^nixos-\d{2}\.\d{2}$", val):
        return f"github:NixOS/nixpkgs/{val}"

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
                        ref = f"/{orig.get('ref')}" if orig.get("ref") else ""
                        return f"git+{orig.get('url')}{ref}"
                    elif orig.get("url"):
                        return orig.get("url")
            except Exception:
                pass

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


def eval_nix_raw(expr: str, flake_input: Optional[str] = None) -> Optional[str]:
    """Evaluate a raw Nix expression via 'nix eval --raw' and return trimmed string."""
    flake_dir = find_flake_dir()
    flake_prefix = f"{flake_dir}#" if flake_dir else ""

    cmd = ["nix", "eval", "--raw", "--impure"]

    if flake_input and not expr.startswith("builtins.") and not expr.startswith("import"):
        if flake_input.startswith("github:") or flake_input.startswith("gitlab:") or flake_input.startswith("path:"):
            eval_expr = f'(builtins.getFlake "{flake_input}").legacyPackages.x86_64-linux.{expr}'
        else:
            eval_expr = f'(builtins.getFlake "{flake_prefix}").inputs.{flake_input}.legacyPackages.x86_64-linux.{expr}'
        cmd.extend(["--expr", eval_expr])
    else:
        cmd.extend(["--expr", expr])

    try:
        res = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
        if res.returncode == 0:
            return res.stdout.strip()
    except Exception:
        pass
    return None


def extract_version_from_store_path(store_path: str) -> str:
    """Extract human-readable version from a Nix store path string."""
    base = os.path.basename(store_path)
    # Remove the 32-char hash prefix (e.g. 86nhn0hbzqww5s85573nyfw5ci1xc882-rclone-1.75.0)
    parts = base.split("-", 1)
    if len(parts) < 2:
        return "unknown"
    pkg_full_name = parts[1]
    match = re.search(r"-(\d[\w\.\-]+)$", pkg_full_name)
    if match:
        return match.group(1)
    return "pinned"


def is_path_in_nix_store(store_path: str) -> bool:
    """Check if a store path physically exists and is genuinely valid in the Nix SQLite database."""
    if not store_path or not store_path.startswith("/nix/store/") or not os.path.exists(store_path):
        return False
    try:
        res = subprocess.run(
            ["nix-store", "--query", "--references", store_path],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=3,
        )
        return res.returncode == 0
    except Exception:
        return False


def compare_versions(v1: str, v2: str) -> int:
    """Compare two version strings (SemVer, date-based, or alpha/beta).

    Returns:
         1 if v1 > v2 (v1 is newer)
         0 if v1 == v2
        -1 if v1 < v2 (v1 is older / downgrade)
    """
    if not v1 or not v2 or v1 == "unknown" or v2 == "unknown":
        return 0 if v1 == v2 else (1 if v1 and v1 != "unknown" else -1)

    if v1 == v2:
        return 0

    nums1 = [int(n) for n in re.findall(r"\d+", v1)]
    nums2 = [int(n) for n in re.findall(r"\d+", v2)]

    if nums1 and nums2:
        for n1, n2 in zip(nums1, nums2):
            if n1 > n2:
                return 1
            elif n1 < n2:
                return -1
        if len(nums1) > len(nums2):
            return 1
        elif len(nums1) < len(nums2):
            return -1

    return 1 if v1 > v2 else -1


def evaluate_upstream_package(
    target_key: str,
    nixpkgs_input: str = "nixpkgs",
) -> Tuple[Optional[str], str, Optional[str]]:
    """Smart evaluator for upstream packages that handles underscores, dashes, python packages, and flake expressions."""
    clean_key = target_key.replace("pkgs.", "")
    var_dash = clean_key.replace("_", "-")
    var_under = clean_key.replace("-", "_")

    candidates = [clean_key]
    if var_dash not in candidates:
        candidates.append(var_dash)
    if var_under not in candidates:
        candidates.append(var_under)

    prefixes = [
        "",
        "pkgs.",
        "python3Packages.",
        "pkgs.python3Packages.",
        "python314Packages.",
        "pkgs.python314Packages.",
        "python313Packages.",
        "pkgs.python313Packages.",
        "python312Packages.",
        "pkgs.python312Packages.",
        "linuxPackages.",
        "pkgs.linuxPackages.",
    ]

    for attr in candidates:
        for prefix in prefixes:
            base_expr = f"{prefix}{attr}"
            sp = eval_nix_raw(f"{base_expr}.outPath", nixpkgs_input)
            if sp and sp.startswith("/nix/store/"):
                ver = eval_nix_raw(f"{base_expr}.version", nixpkgs_input) or extract_version_from_store_path(sp)
                main_prog = eval_nix_raw(f"{base_expr}.meta.mainProgram", nixpkgs_input)
                return sp, ver, main_prog

    return None, "unknown", None


def resolve_target_to_store_path(
    target: str,
    nixpkgs_input: str = "nixpkgs",
    pins_file: Optional[Path] = None,
) -> Tuple[str, str, Optional[str]]:
    """Resolve a target name, attr, or store path into a validated (store_path, version, main_program) tuple."""
    # 1. Direct Store Path
    if target.startswith("/nix/store/"):
        store_path = target.rstrip("/")
        version = extract_version_from_store_path(store_path)
        return store_path, version, None

    clean_target = target.replace("pkgs.", "")
    var_dash = clean_target.replace("_", "-")
    var_under = clean_target.replace("-", "_")

    # 2. Check local pins_file registry
    if pins_file and pins_file.is_file():
        try:
            expr = f"import {pins_file}"
            res = subprocess.run(
                ["nix", "eval", "--json", "--impure", "--expr", expr],
                capture_output=True,
                text=True,
                timeout=10,
            )
            if res.returncode == 0:
                data = json.loads(res.stdout)
                for key_candidate in [clean_target, var_dash, var_under]:
                    if key_candidate in data:
                        entry = data[key_candidate]
                        if isinstance(entry, dict) and "storePath" in entry:
                            sp = entry["storePath"]
                            ver = entry.get("version") or extract_version_from_store_path(sp)
                            main_prog = entry.get("mainProgram")
                            return sp, ver, main_prog
        except Exception:
            pass

    # 3. Flake evaluation with channel target
    for attr in [clean_target, var_dash, var_under]:
        store_path = eval_nix_raw(f"{attr}.outPath", nixpkgs_input)
        if store_path and store_path.startswith("/nix/store/"):
            version = (
                eval_nix_raw(f"{attr}.version", nixpkgs_input)
                or extract_version_from_store_path(store_path)
            )
            main_program = eval_nix_raw(f"{attr}.meta.mainProgram", nixpkgs_input)
            return store_path, version, main_program

    # 4. Smart recursive search in flake inputs and configs
    flake_dir = find_flake_dir()
    if flake_dir:
        flake_prefix = f"{flake_dir}#"
        smart_expr = f"""
        let
          fl = builtins.getFlake "{flake_prefix}";
          inputs = fl.inputs or {{}};
          cfgs = builtins.attrValues (fl.nixosConfigurations or {{}});

          checkPkg = p:
            if p != null && (p ? outPath || builtins.isPath p)
            then builtins.unsafeDiscardStringContext (toString p.outPath or p)
            else "";

          searchInputs = builtins.concatLists (
            builtins.map (inp:
              let
                pk = inp.legacyPackages.x86_64-linux or inp.packages.x86_64-linux or {{}};
                res = checkPkg (pk."{clean_target}" or pk."{var_dash}" or pk."{var_under}" or null);
              in
                if res != "" then [ res ] else []
            ) (builtins.attrValues inputs)
          );

          searchConfigs =
            let
              res = builtins.map (c:
                let
                  pk = c.pkgs or {{}};
                  k = c.config.boot.kernelPackages.kernel or null;
                  checkC = if "{clean_target}" == "cachyos-kernel" || "{clean_target}" == "kernel"
                           then checkPkg (pk.linuxPackages_cachyos.kernel or null)
                           else "";
                  checkK = if "{clean_target}" == "kernel" || "{clean_target}" == "boot.kernelPackages"
                           then checkPkg k
                           else "";
                  checkP = checkPkg (pk."{clean_target}" or pk."{var_dash}" or pk."{var_under}" or null);
                in
                  if checkC != "" then checkC else if checkK != "" then checkK else checkP
              ) cfgs;
            in
              builtins.filter (x: x != "") res;

          finalList = searchInputs ++ searchConfigs;
        in
          if finalList != [] then builtins.head finalList else ""
        """
        store_path = eval_nix_raw(smart_expr)
        if store_path and store_path.startswith("/nix/store/"):
            version = extract_version_from_store_path(store_path)
            return store_path, version, None

    raise RuntimeError(
        f"Tidak dapat menemukan store path untuk '{target}'. "
        "Pastikan nama valid atau terdaftar di modules/_lib/cache-pins.nix."
    )
