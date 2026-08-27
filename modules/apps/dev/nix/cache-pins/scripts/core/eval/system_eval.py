"""NixOS system toplevel evaluation and missing closure / FOD discovery."""

import json
import os
from pathlib import Path
import re
import socket
import subprocess
import sys
from typing import Dict, List, Optional, Tuple

from core.eval.channels import find_flake_dir, get_nix_env
from core.eval.resolver import is_path_in_nix_store
from core.models import FodDownloadItem


def get_system_hostname(flake_dir: Optional[Path] = None) -> str:
    """Resolve current NixOS hostname."""
    env_host = os.environ.get("NIXOS_HOST") or os.environ.get("HOSTNAME")
    if env_host:
        return env_host

    try:
        host = socket.gethostname()
        if host:
            return host
    except Exception:
        pass

    # Default fallback
    return "KleinMoretti"


def get_system_toplevel_attr(
    flake_dir: Optional[Path] = None, hostname: Optional[str] = None
) -> str:
    """Get flake target attribute for system toplevel."""
    host = hostname or get_system_hostname(flake_dir)
    return f".#nixosConfigurations.{host}.config.system.build.toplevel"


def extract_missing_fods(
    drv_paths: List[str], env: Optional[Dict[str, str]] = None
) -> List[FodDownloadItem]:
    """Inspect derivations using `nix show-derivation` and identify missing Fixed-Output Derivations (FODs)."""
    if not drv_paths:
        return []

    cmd = ["nix", "show-derivation"] + drv_paths
    res = subprocess.run(cmd, capture_output=True, text=True, env=env or get_nix_env())
    if res.returncode != 0 or not res.stdout.strip():
        return []

    try:
        data = json.loads(res.stdout)
    except Exception:
        return []

    drvs = data.get("derivations", data)
    missing_fods: List[FodDownloadItem] = []

    for drv_path, drv in drvs.items():
        if not isinstance(drv, dict):
            continue

        env_map = drv.get("env", {})
        attrs = drv.get("structuredAttrs", {})

        output_hash = env_map.get("outputHash") or attrs.get("outputHash")
        if not output_hash:
            continue

        output_hash_algo = env_map.get("outputHashAlgo") or attrs.get("outputHashAlgo") or "sha256"
        output_hash_mode = env_map.get("outputHashMode") or attrs.get("outputHashMode", "flat")

        raw_urls = attrs.get("urls") or env_map.get("urls") or []
        if isinstance(raw_urls, str):
            urls = raw_urls.split()
        elif isinstance(raw_urls, list):
            urls = raw_urls
        else:
            urls = []

        if not urls:
            continue

        out_path = env_map.get("out") or drv.get("outputs", {}).get("out", {}).get("path")
        if not out_path:
            continue

        if is_path_in_nix_store(out_path):
            continue

        filename = os.path.basename(out_path)
        parts = filename.split("-", 1)
        pure_filename = parts[1] if len(parts) == 2 and len(parts[0]) == 32 else filename

        item = FodDownloadItem(
            drv_path=drv_path,
            out_path=out_path,
            url=urls[0],
            filename=pure_filename,
            hash_algo=output_hash_algo,
            hash_value=output_hash,
            hash_mode=output_hash_mode,
        )
        missing_fods.append(item)

    return missing_fods


def evaluate_system_missing_paths(
    flake_dir: Optional[Path] = None,
    hostname: Optional[str] = None,
    verbose: bool = False,
) -> Tuple[List[str], List[FodDownloadItem], Dict[str, str]]:
    """Run dry-run build on system toplevel and parse store paths that must be fetched or built via FOD.

    Returns:
        Tuple of (missing_substituter_paths, missing_fods, summary_metadata)
    """
    root_dir = flake_dir or find_flake_dir()
    if not root_dir:
        raise RuntimeError("Direktori flake (berisi flake.nix) tidak ditemukan.")

    target_attr = get_system_toplevel_attr(root_dir, hostname)
    cmd = ["nix", "build", "--dry-run", target_attr]

    env = get_nix_env()

    if verbose:
        print(f"🔧 Menjalankan: {' '.join(cmd)} (di {root_dir})", file=sys.stderr)

    res = subprocess.run(
        cmd,
        cwd=str(root_dir),
        capture_output=True,
        text=True,
        env=env,
    )

    output = (res.stderr or "") + "\n" + (res.stdout or "")

    missing_paths: List[str] = []
    candidate_drvs: List[str] = []
    in_fetch_section = False
    in_build_section = False

    metadata: Dict[str, str] = {
        "target": target_attr,
        "summary": "0 paket (seluruh biner sudah ada di lokal)",
        "download_size": "0 B",
        "unpacked_size": "0 B",
    }

    for line in output.splitlines():
        line_clean = line.strip()

        # Check section header: "these N paths will be fetched (...):" or "this path will be fetched (...):"
        fetch_match = re.search(
            r"\b(?:these \d+|this) path(?:s)? will be fetched \(([^)]+)\):?",
            line_clean,
            re.IGNORECASE,
        )
        if fetch_match:
            in_fetch_section = True
            in_build_section = False
            size_info = fetch_match.group(1)
            metadata["summary"] = size_info
            parts = [p.strip() for p in size_info.split(",")]
            for p in parts:
                if "download" in p:
                    metadata["download_size"] = p.replace("download", "").strip()
                elif "unpacked" in p:
                    metadata["unpacked_size"] = p.replace("unpacked", "").strip()
            continue

        build_match = re.search(
            r"\b(?:these \d+|this) derivation(?:s)? will be built:?",
            line_clean,
            re.IGNORECASE,
        )
        if build_match:
            in_build_section = True
            in_fetch_section = False
            continue

        if in_fetch_section:
            if line.startswith(" ") or line.startswith("\t"):
                if line_clean.startswith("/nix/store/"):
                    sp = line_clean.split()[0]
                    if sp not in missing_paths:
                        missing_paths.append(sp)
            elif line_clean.startswith("these ") or line_clean.startswith("this "):
                in_fetch_section = False

        if in_build_section:
            if line.startswith(" ") or line.startswith("\t"):
                if line_clean.startswith("/nix/store/") and line_clean.endswith(".drv"):
                    drv_p = line_clean.split()[0]
                    if drv_p not in candidate_drvs:
                        candidate_drvs.append(drv_p)
            elif line_clean.startswith("these ") or line_clean.startswith("this "):
                in_build_section = False

    missing_fods = extract_missing_fods(candidate_drvs, env=env)
    return missing_paths, missing_fods, metadata
