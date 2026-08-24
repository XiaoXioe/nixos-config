"""Downloader package for RAM tmpfs cache management, aria2c execution, and nix-store ingestion."""

from downloader.aria2 import (
    ensure_aria2_installed,
    generate_aria2_batch_file,
    run_aria2_download,
)
from downloader.ingest import ingest_store_paths
from downloader.orchestrator import download_batch_targets, download_single_target
from downloader.ram_cache import (
    cleanup_ram_cache,
    get_default_ram_cache_dir,
    setup_ram_cache_dir,
)

__all__ = [
    "cleanup_ram_cache",
    "download_batch_targets",
    "download_single_target",
    "ensure_aria2_installed",
    "generate_aria2_batch_file",
    "get_default_ram_cache_dir",
    "ingest_store_paths",
    "run_aria2_download",
    "setup_ram_cache_dir",
]
