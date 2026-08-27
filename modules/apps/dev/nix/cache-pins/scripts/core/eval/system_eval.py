"""NixOS system toplevel evaluation and missing closure discovery."""

import os
import re
import socket
import subprocess
import sys
from pathlib import Path
from typing import Dict, List, Optional, Tuple

from core.eval.channels import find_flake_dir, get_nix_env


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


def evaluate_system_missing_paths(
    flake_dir: Optional[Path] = None,
    hostname: Optional[str] = None,
    verbose: bool = False,
) -> Tuple[List[str], Dict[str, str]]:
    """Run dry-run build on system toplevel and parse store paths that must be fetched.

    Returns:
        Tuple of (missing_store_paths, summary_metadata)
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

    # nix build --dry-run prints its report to stderr
    output = (res.stderr or "") + "\n" + (res.stdout or "")

    missing_paths: List[str] = []
    in_fetch_section = False
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
            size_info = fetch_match.group(1)
            metadata["summary"] = size_info
            parts = [p.strip() for p in size_info.split(",")]
            for p in parts:
                if "download" in p:
                    metadata["download_size"] = p.replace("download", "").strip()
                elif "unpacked" in p:
                    metadata["unpacked_size"] = p.replace("unpacked", "").strip()
            continue

        if in_fetch_section:
            if line.startswith(" ") or line.startswith("\t"):
                if line_clean.startswith("/nix/store/"):
                    sp = line_clean.split()[0]
                    if sp not in missing_paths:
                        missing_paths.append(sp)
            elif line_clean.startswith("these ") or line_clean.startswith("this "):
                # Next section (e.g. "these 25 derivations will be built:")
                in_fetch_section = False

    return missing_paths, metadata
