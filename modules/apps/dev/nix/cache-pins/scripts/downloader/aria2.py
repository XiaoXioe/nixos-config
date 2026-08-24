"""Aria2c multi-connection parallel downloader runner and batch input generator."""
from pathlib import Path
import subprocess
import sys
from typing import List

from core.models import DownloadItem


def ensure_aria2_installed():
    """Verify that aria2c executable is installed and reachable in PATH."""
    which_aria2 = subprocess.run(["which", "aria2c"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    if which_aria2.returncode != 0:
        which_aria2 = subprocess.run(
            ["command", "-v", "aria2c"], shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
        )
        if which_aria2.returncode != 0:
            print("❌ ERROR: 'aria2c' tidak ditemukan di sistem Anda.", file=sys.stderr)
            print("   Silakan instal aria2 atau jalankan via nix-shell.", file=sys.stderr)
            sys.exit(1)


def generate_aria2_batch_file(
    items: List[DownloadItem], batch_file_path: Path, nar_dir: Path
):
    """Write an aria2 batch input file for parallel downloads."""
    with open(batch_file_path, "w", encoding="utf-8") as f:
        for item in items:
            f.write(f"{item.url}\n")
            f.write(f"  dir={nar_dir}\n")
            f.write(f"  out={item.filename}\n")


def run_aria2_download(
    batch_file_path: Path,
    nar_dir: Path,
    concurrent: int = 4,
    split: int = 8,
) -> int:
    """Execute aria2c with multi-connection acceleration."""
    aria2_cmd = [
        "aria2c",
        f"--input-file={batch_file_path}",
        "--continue=true",
        f"--max-concurrent-downloads={concurrent}",
        f"--max-connection-per-server={split}",
        f"--split={split}",
        "--min-split-size=1M",
        "--max-tries=0",
        "--retry-wait=2",
        "--connect-timeout=30",
        "--timeout=60",
        "--auto-file-renaming=false",
        "--allow-overwrite=true",
        f"--dir={nar_dir}",
    ]
    res = subprocess.run(aria2_cmd)
    return res.returncode
