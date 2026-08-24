"""Core package for Nix evaluation, binary cache HTTP client, DAG closure traversal, and data models."""

from core.cache_client import NixCacheClient, get_system_substituters
from core.closure import ClosureAuditor
from core.models import ClosureAudit, DownloadItem, NarInfo, PinEntry, UpdateType
from core.nix_eval import (
    compare_versions,
    eval_nix_raw,
    evaluate_upstream_package,
    extract_version_from_store_path,
    find_cache_pins_file,
    find_flake_dir,
    is_path_in_nix_store,
    resolve_channel_input,
    resolve_target_to_store_path,
)

__all__ = [
    "ClosureAudit",
    "ClosureAuditor",
    "DownloadItem",
    "NarInfo",
    "NixCacheClient",
    "PinEntry",
    "UpdateType",
    "compare_versions",
    "eval_nix_raw",
    "evaluate_upstream_package",
    "extract_version_from_store_path",
    "find_cache_pins_file",
    "find_flake_dir",
    "get_system_substituters",
    "is_path_in_nix_store",
    "resolve_channel_input",
    "resolve_target_to_store_path",
]
