"""Persistent local disk cache manager for Nix package evaluation results."""
import json
import os
from pathlib import Path
import re
import tempfile
from typing import Dict, List, Optional, Tuple

from core.cache.tracker import get_channel_revision_info
from core.models import PackageMeta


def get_cache_root_dir() -> Path:
    """Get the base directory for local ncp evaluation caches."""
    env_cache = os.environ.get("NCP_CACHE_DIR")
    if env_cache:
        return Path(env_cache).resolve()

    xdg_cache = os.environ.get("XDG_CACHE_HOME")
    if xdg_cache:
        return (Path(xdg_cache) / "ncp").resolve()

    return (Path.home() / ".cache" / "ncp").resolve()


class LocalDiskCache:
    """Disk-backed cache storing package metadata keyed by upstream channel revision."""

    def __init__(self, base_dir: Optional[Path] = None):
        self.base_dir = (base_dir or get_cache_root_dir()) / "eval"
        self.base_dir.mkdir(parents=True, exist_ok=True)

    def _get_cache_file_path(self, channel_key: str, revision: str) -> Path:
        safe_channel = re.sub(r"[^a-zA-Z0-9_-]", "_", channel_key)
        safe_rev = re.sub(r"[^a-zA-Z0-9_-]", "_", revision)
        chan_dir = self.base_dir / safe_channel
        chan_dir.mkdir(parents=True, exist_ok=True)
        return chan_dir / f"{safe_rev}.json"

    def _read_cache_payload(self, file_path: Path) -> Dict[str, PackageMeta]:
        if not file_path.is_file():
            return {}
        try:
            raw_data = json.loads(file_path.read_text(encoding="utf-8"))
            pkgs = raw_data.get("packages", {})
            result = {}
            for k, v in pkgs.items():
                if isinstance(v, dict) and "store_path" in v or "storePath" in v:
                    result[k] = PackageMeta.from_dict(v)
            return result
        except Exception:
            return {}

    def get_batch(
        self,
        channel_or_input: str,
        target_keys: List[str],
        bypass_cache: bool = False,
    ) -> Tuple[Dict[str, PackageMeta], List[str]]:
        """Retrieve cached package metadata for a channel revision.

        Returns:
            Tuple of (cached_packages_map, missing_keys_list)
        """
        if bypass_cache:
            return {}, list(target_keys)

        rev_info = get_channel_revision_info(channel_or_input)
        cache_file = self._get_cache_file_path(rev_info.channel_key, rev_info.revision)

        cached_data = self._read_cache_payload(cache_file)
        hits: Dict[str, PackageMeta] = {}
        missing: List[str] = []

        for k in target_keys:
            clean_k = k.replace("pkgs.", "").strip()
            if clean_k in cached_data:
                hits[k] = cached_data[clean_k]
            else:
                missing.append(k)

        return hits, missing

    def get(
        self,
        channel_or_input: str,
        target_key: str,
        bypass_cache: bool = False,
    ) -> Optional[PackageMeta]:
        """Retrieve a single cached package metadata entry."""
        hits, missing = self.get_batch(channel_or_input, [target_key], bypass_cache=bypass_cache)
        return hits.get(target_key)

    def set_batch(
        self,
        channel_or_input: str,
        evaluated_packages: Dict[str, PackageMeta],
    ) -> None:
        """Atomically persist evaluated package metadata into the disk cache."""
        if not evaluated_packages:
            return

        rev_info = get_channel_revision_info(channel_or_input)
        cache_file = self._get_cache_file_path(rev_info.channel_key, rev_info.revision)

        existing = self._read_cache_payload(cache_file)
        for k, meta in evaluated_packages.items():
            if meta and meta.store_path:
                clean_k = k.replace("pkgs.", "").strip()
                existing[clean_k] = meta

        payload = {
            "version": 1,
            "channel_input": rev_info.channel_input,
            "revision": rev_info.revision,
            "last_modified": rev_info.last_modified,
            "packages": {k: m.to_dict() for k, m in existing.items()},
        }

        # Atomic write
        temp_file = cache_file.with_suffix(".tmp")
        try:
            temp_file.write_text(json.dumps(payload, indent=2), encoding="utf-8")
            temp_file.replace(cache_file)
        except Exception:
            if temp_file.exists():
                try:
                    temp_file.unlink()
                except Exception:
                    pass

    def invalidate(self, channel_or_input: Optional[str] = None) -> None:
        """Clear cache entries for a specific channel or all channels."""
        if channel_or_input:
            rev_info = get_channel_revision_info(channel_or_input)
            safe_channel = re.sub(r"[^a-zA-Z0-9_-]", "_", rev_info.channel_key)
            chan_dir = self.base_dir / safe_channel
            if chan_dir.is_dir():
                for f in chan_dir.glob("*.json"):
                    try:
                        f.unlink()
                    except Exception:
                        pass
        else:
            if self.base_dir.is_dir():
                import shutil
                shutil.rmtree(self.base_dir, ignore_errors=True)
                self.base_dir.mkdir(parents=True, exist_ok=True)
