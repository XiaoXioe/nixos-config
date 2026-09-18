"""Downloader package for RAM tmpfs cache management, aria2c execution, and nix-store ingestion."""

from downloader.aria2 import (
    build_aria2_cmd,
    ensure_aria2_installed,
    generate_aria2_batch_file,
    launch_aria2_process,
    run_aria2_download,
)
from downloader.ingest import ingest_fod_items, ingest_single_fod, ingest_store_paths
from downloader.orchestrator import (
    download_batch_targets,
    download_fod_target,
    download_single_target,
    download_system_targets,
)
from downloader.pipeline import DAGResolver, StreamingIngestPipeline
from downloader.ram_cache import (
    cleanup_ram_cache,
    get_default_ram_cache_dir,
    setup_ram_cache_dir,
)

__all__ = [
    "cleanup_ram_cache",
    "download_batch_targets",
    "download_fod_target",
    "download_single_target",
    "download_system_targets",
    "ensure_aria2_installed",
    "generate_aria2_batch_file",
    "get_default_ram_cache_dir",
    "ingest_fod_items",
    "ingest_single_fod",
    "ingest_store_paths",
    "launch_aria2_process",
    "run_aria2_download",
    "setup_ram_cache_dir",
    "build_aria2_cmd",
    "DAGResolver",
    "StreamingIngestPipeline",
]
