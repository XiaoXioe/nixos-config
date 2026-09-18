"""Aria2c multi-connection parallel downloader runner and batch input generator."""
from pathlib import Path
import subprocess
import sys
from typing import List, Optional

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


def build_aria2_cmd(
    batch_file_path: Path,
    nar_dir: Path,
    concurrent: int = 4,
    split: int = 8,
    on_download_complete: Optional[str] = None,
    on_download_error: Optional[str] = None,
    quiet: bool = False,
) -> List[str]:
    """Construct command-line arguments for aria2c execution."""
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
        "--console-log-level=warn",
        "--download-result=hide",
        "--summary-interval=0",
        f"--dir={nar_dir}",
    ]
    if on_download_complete:
        aria2_cmd.append(f"--on-download-complete={on_download_complete}")
    if on_download_error:
        aria2_cmd.append(f"--on-download-error={on_download_error}")
    if quiet:
        aria2_cmd.append("--quiet=true")
    return aria2_cmd


def launch_aria2_process(
    batch_file_path: Path,
    nar_dir: Path,
    concurrent: int = 4,
    split: int = 8,
    on_download_complete: Optional[str] = None,
    on_download_error: Optional[str] = None,
    quiet: bool = False,
) -> subprocess.Popen:
    """Launch aria2c as an asynchronous subprocess."""
    cmd = build_aria2_cmd(
        batch_file_path=batch_file_path,
        nar_dir=nar_dir,
        concurrent=concurrent,
        split=split,
        on_download_complete=on_download_complete,
        on_download_error=on_download_error,
        quiet=quiet,
    )
    return subprocess.Popen(cmd)


def run_aria2_download(
    batch_file_path: Path,
    nar_dir: Path,
    concurrent: int = 4,
    split: int = 8,
    on_download_complete: Optional[str] = None,
    on_download_error: Optional[str] = None,
) -> int:
    """Execute aria2c with multi-connection acceleration."""
    cmd = build_aria2_cmd(
        batch_file_path=batch_file_path,
        nar_dir=nar_dir,
        concurrent=concurrent,
        split=split,
        on_download_complete=on_download_complete,
        on_download_error=on_download_error,
    )
    res = subprocess.run(cmd)
    return res.returncode
