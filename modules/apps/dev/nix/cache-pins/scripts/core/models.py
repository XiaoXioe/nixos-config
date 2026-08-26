"""Data models for Nix Binary Cache NarInfo, Closure Audits, Downloads, and Pin Entries."""
from dataclasses import dataclass, field
from enum import Enum
from typing import Any, Dict, List, Optional


class UpdateType(str, Enum):
    """Classification of package update states."""

    UP_TO_DATE = "up_to_date"
    VERSION_BUMP = "version_bump"
    REBUILD_UPDATE = "rebuild_update"
    DOWNGRADE_BLOCKED = "downgrade_blocked"
    CACHE_MISS = "cache_miss"
    EVAL_FAILED = "eval_failed"


@dataclass
class NarInfo:
    """Represents the parsed metadata of a .narinfo binary cache file."""

    store_path: str
    hash: str
    name: str
    url: Optional[str] = None
    compression: Optional[str] = None
    file_size: int = 0
    nar_size: int = 0
    nar_hash: Optional[str] = None
    references: List[str] = field(default_factory=list)
    raw_text: str = ""
    source_cache_url: str = "https://cache.nixos.org"


@dataclass
class ClosureAudit:
    """Comprehensive analysis result of a package closure and its dependency DAG."""

    target_name: str
    store_path: str
    version: str
    main_program: Optional[str]
    cache_url: str
    compression: str
    file_size: int
    nar_size: int
    total_refs: int
    local_count: int
    missing_count: int
    target_glibc: str
    glibc_local: bool
    target_is_local: bool
    gross_download: int
    gross_disk: int
    net_download: int
    net_disk: int
    saved_bandwidth: int
    saved_percent: float
    local_percent: float
    missing_items: List[Dict[str, Any]]
    all_items: List[Dict[str, Any]]


@dataclass
class DownloadItem:
    """Represents an individual .nar archive file to be downloaded via aria2."""

    hash: str
    url: str
    filename: str
    file_size: int
    source_cache_url: str = "https://cache.nixos.org"


@dataclass
class PinEntry:
    """Represents an entry in modules/_lib/cache-pins.nix."""

    name: str
    store_path: str
    version: str = ""
    system: str = "x86_64-linux"
    channel: Optional[str] = None
    main_program: Optional[str] = None
    from_store: Optional[str] = None
    raw_snippet: str = ""


@dataclass
class UpdateResult:
    """Result of checking a single pin against upstream."""
    key: str
    current_store_path: str
    current_version: str
    new_store_path: Optional[str] = None
    new_version: str = "unknown"
    main_program: Optional[str] = None
    update_type: UpdateType = UpdateType.UP_TO_DATE
    effective_input: str = "nixpkgs"
