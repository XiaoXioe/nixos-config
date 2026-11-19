"""Data models for Nix Binary Cache NarInfo, Closure Audits, and Downloads."""
from dataclasses import asdict, dataclass, field
from typing import Any, Dict, List, Optional

from core.platform import get_current_system


@dataclass
class PackageMeta:
    """Evaluated metadata for a package from upstream or local cache."""

    store_path: str
    version: str = "unknown"
    main_program: Optional[str] = None
    pname: Optional[str] = None
    system: str = field(default_factory=get_current_system)
    channel: Optional[str] = None
    from_store: Optional[str] = None

    def to_dict(self) -> Dict[str, Any]:
        return {k: v for k, v in asdict(self).items() if v is not None}

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "PackageMeta":
        return cls(
            store_path=data.get("storePath") or data.get("store_path", ""),
            version=data.get("version", "unknown"),
            main_program=data.get("mainProgram") or data.get("main_program"),
            pname=data.get("pname"),
            system=data.get("system") or get_current_system(),
            channel=data.get("channel"),
            from_store=data.get("fromStore") or data.get("from_store"),
        )


@dataclass
class ChannelRevInfo:
    """Channel commit revision and tracking identifier."""

    channel_input: str
    channel_key: str
    revision: str
    last_modified: Optional[int] = None
    nar_hash: Optional[str] = None
    store_path: Optional[str] = None
    locked_url: Optional[str] = None
    is_local_flake: bool = False


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
    system: str = field(default_factory=get_current_system)


@dataclass
class DownloadItem:
    """Represents an individual .nar archive file to be downloaded via aria2."""

    hash: str
    url: str
    filename: str
    file_size: int
    source_cache_url: str = "https://cache.nixos.org"


@dataclass
class FodDownloadItem:
    """Represents a Fixed-Output Derivation (FOD / fetchurl / fetchzip) to be downloaded directly from upstream."""

    drv_path: str
    out_path: str
    url: str
    filename: str
    hash_algo: str
    hash_value: str
    hash_mode: str = "flat"
    file_size: int = 0
    download_filename: Optional[str] = None
    strip_root: bool = True
    post_fetch: Optional[str] = None
