"""RAM tmpfs lifecycle management for Zero SSD Wear NAR downloads."""
import os
from pathlib import Path
import shutil
from typing import Tuple


def get_default_ram_cache_dir() -> str:
    """Get the preferred RAM tmpfs directory path."""
    env_dir = os.environ.get("LOCAL_CACHE_DIR")
    if env_dir:
        return env_dir

    runtime_dir = os.environ.get("XDG_RUNTIME_DIR")
    if runtime_dir and os.path.isdir(runtime_dir):
        return str(Path(runtime_dir) / "nix-aria2")

    if os.path.isdir("/dev/shm"):
        return f"/dev/shm/nix-aria2-{os.getuid()}"

    return f"/tmp/nix-aria2-{os.getuid()}"


def setup_ram_cache_dir(cache_dir: Path) -> Tuple[Path, Path]:
    """Initialize local RAM cache structure (nix-cache-info and nar/ folder)."""
    cache_dir.mkdir(parents=True, exist_ok=True)
    nar_dir = cache_dir / "nar"
    nar_dir.mkdir(parents=True, exist_ok=True)

    cache_info_file = cache_dir / "nix-cache-info"
    if not cache_info_file.exists():
        cache_info_file.write_text("StoreDir: /nix/store\nWantMassQuery: 0\nPriority: 0\n")

    return cache_dir, nar_dir


def cleanup_ram_cache(nar_dir: Path):
    """Clean up downloaded .nar archives from RAM tmpfs."""
    if nar_dir.exists():
        shutil.rmtree(nar_dir, ignore_errors=True)
        nar_dir.mkdir(parents=True, exist_ok=True)
