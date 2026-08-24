"""Nix store realisation and ingestion from local tmpfs cache."""
from pathlib import Path
import subprocess
from typing import List, Union


def ingest_store_paths(
    store_paths: Union[str, List[str]],
    local_cache_dir: Path,
    cache_urls: List[str],
) -> bool:
    """Ingest store paths from local RAM cache to /nix/store via nix-store --realise."""
    paths = [store_paths] if isinstance(store_paths, str) else store_paths
    substituters_str = f"file://{local_cache_dir}?priority=0 " + " ".join(
        [f"{u}?priority=100" for u in cache_urls]
    )

    all_ok = True
    for sp in paths:
        cmd = [
            "nix-store",
            "--realise",
            sp,
            "--option",
            "substituters",
            substituters_str,
            "--option",
            "trusted-substituters",
            f"file://{local_cache_dir}",
            "--option",
            "fallback",
            "false",
        ]
        res = subprocess.run(cmd, stdout=subprocess.DEVNULL)
        if res.returncode != 0:
            all_ok = False

    return all_ok
