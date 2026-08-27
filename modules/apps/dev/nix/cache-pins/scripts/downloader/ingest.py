"""Nix store realisation and ingestion from local tmpfs cache."""
from pathlib import Path
import subprocess
import sys
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
        res = subprocess.run(cmd, capture_output=True, text=True)
        if res.returncode != 0:
            print(f"❌ Ingestion error for {sp}:", file=sys.stderr)
            if res.stderr:
                for line in res.stderr.strip().splitlines():
                    print(f"   {line}", file=sys.stderr)
            all_ok = False

    return all_ok


def ingest_fod_items(
    fod_items: List["FodDownloadItem"],
    download_dir: Path,
) -> bool:
    """Ingest downloaded Fixed-Output Derivation (FOD) files into /nix/store via nix-store --add-fixed."""
    all_ok = True
    for item in fod_items:
        file_path = download_dir / item.filename
        if not file_path.exists():
            print(f"❌ ERROR: Berkas FOD '{item.filename}' tidak ditemukan di {download_dir}.", file=sys.stderr)
            all_ok = False
            continue

        cmd = ["nix-store", "--add-fixed"]
        if item.hash_mode == "recursive":
            cmd.append("--recursive")
        cmd.extend([item.hash_algo, str(file_path)])

        res = subprocess.run(cmd, capture_output=True, text=True)
        if res.returncode != 0:
            print(f"❌ Gagal meng-ingest berkas FOD '{item.filename}' ke /nix/store:", file=sys.stderr)
            if res.stderr:
                for line in res.stderr.strip().splitlines():
                    print(f"   {line}", file=sys.stderr)
            all_ok = False
        else:
            resulting_path = res.stdout.strip()
            if item.out_path and resulting_path != item.out_path:
                print(f"⚠️ PERINGATAN: Store path hasil ({resulting_path}) berbeda dari yang diharapkan ({item.out_path})!", file=sys.stderr)
            else:
                print(f"  ✔ [FOD Ingest] {item.filename} ➔ {resulting_path}", file=sys.stderr)

    return all_ok
