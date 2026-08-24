"""Data models for Nix Binary Cache NarInfo, Closure Audits, and Downloads."""
from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional


@dataclass
class NarInfo:
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
    hash: str
    url: str
    filename: str
    file_size: int
    source_cache_url: str = "https://cache.nixos.org"
