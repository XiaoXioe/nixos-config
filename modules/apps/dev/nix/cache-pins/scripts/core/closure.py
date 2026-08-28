"""Nix closure DAG traversal, local store auditing, and bandwidth calculation."""
import concurrent.futures
import json
import os
from pathlib import Path
import re
import subprocess
from typing import Any, Dict, List, Optional, Set, Tuple

from core.cache_client import NixCacheClient
from core.eval.channels import get_nix_env
from core.eval.resolver import is_path_in_nix_store
from core.models import ClosureAudit, DownloadItem, NarInfo


def get_local_closure_sizes_batch(store_paths: List[str]) -> Dict[str, int]:
    """Retrieve individual closure size in bytes for multiple local store paths in a single batch call."""
    valid_paths = [sp for sp in store_paths if sp and is_path_in_nix_store(sp)]
    if not valid_paths:
        return {}

    cmd = ["nix", "path-info", "--json", "--closure-size"] + valid_paths
    try:
        res = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=15,
            env=get_nix_env(),
        )
        if res.returncode == 0:
            data = json.loads(res.stdout)
            return {
                sp: int(info.get("closureSize", 0))
                for sp, info in data.items()
                if isinstance(info, dict)
            }
    except Exception:
        pass
    return {}


def get_local_unique_footprint(store_paths: List[str]) -> Tuple[int, int, int]:
    """Calculate deduplicated disk footprint, unique store paths count, and cumulative closure size.

    Returns:
        Tuple of (deduplicated_disk_bytes, unique_paths_count, cumulative_closure_bytes)
    """
    valid_paths = [sp for sp in store_paths if sp and is_path_in_nix_store(sp)]
    if not valid_paths:
        return 0, 0, 0

    cmd = ["nix", "path-info", "-r", "--json"] + valid_paths
    dedup_bytes = 0
    unique_count = 0
    try:
        res = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=20,
            env=get_nix_env(),
        )
        if res.returncode == 0:
            data = json.loads(res.stdout)
            dedup_bytes = sum(int(info.get("narSize", 0)) for info in data.values() if isinstance(info, dict))
            unique_count = len(data)
    except Exception:
        pass

    closure_sizes = get_local_closure_sizes_batch(valid_paths)
    cumulative_bytes = sum(closure_sizes.values())

    return dedup_bytes, unique_count, cumulative_bytes


class ClosureAuditor:
    """Performs DAG closure resolution, dependency tree traversal, and local store comparison."""

    def __init__(self, cache_client: NixCacheClient):
        self.client = cache_client
        self._shared_narinfos: Dict[str, NarInfo] = {}

    def audit_closure(
        self,
        target_name: str,
        store_path: str,
        version: str = "",
        main_program: Optional[str] = None,
        system: Optional[str] = None,
    ) -> ClosureAudit:
        """Analyze a store path's full closure, local reuse percentage, and bandwidth savings."""
        target_hash = os.path.basename(store_path.rstrip("/")).split("-")[0]
        target_narinfo = self.client.fetch_narinfo(target_hash)

        if not target_narinfo:
            raise RuntimeError(
                f"Biner untuk store path {store_path} tidak ditemukan di binary cache ({self.client.summary_display}).\n"
                "💡 Catatan: Paket berlisensi 'unfree' (proprietary) atau paket kustom umumnya tidak di-build/di-cache oleh server Hydra resmi (cache.nixos.org)."
            )

        # 1. Traverse closure DAG with shared node memoization
        visited_hashes: Set[str] = set()
        queue = [target_hash]
        local_narinfos: Dict[str, NarInfo] = {}

        while queue:
            current_batch = queue
            queue = []
            to_fetch = []

            for h in current_batch:
                if h in visited_hashes:
                    continue
                visited_hashes.add(h)
                if h in self._shared_narinfos:
                    info = self._shared_narinfos[h]
                    local_narinfos[h] = info
                    for ref in info.references:
                        ref_hash = ref.split("-")[0]
                        if ref_hash not in visited_hashes:
                            queue.append(ref_hash)
                else:
                    to_fetch.append(h)

            if not to_fetch:
                continue

            with concurrent.futures.ThreadPoolExecutor(max_workers=self.client.max_workers) as executor:
                futures = {executor.submit(self.client.fetch_narinfo, h): h for h in to_fetch}
                for f in concurrent.futures.as_completed(futures):
                    h = futures[f]
                    info = f.result()
                    if info:
                        self._shared_narinfos[h] = info
                        local_narinfos[h] = info
                        for ref in info.references:
                            ref_hash = ref.split("-")[0]
                            if ref_hash not in visited_hashes:
                                queue.append(ref_hash)

        # 2. Local vs Missing Partitioning
        local_items: List[Dict[str, Any]] = []
        missing_items: List[Dict[str, Any]] = []
        all_items: List[Dict[str, Any]] = []

        target_glibc = "Unknown"
        glibc_local = False
        target_is_local = is_path_in_nix_store(store_path)

        for h, info in local_narinfos.items():
            sp = f"/nix/store/{info.name}" if not info.store_path else info.store_path
            is_local = is_path_in_nix_store(sp)

            # Detect glibc
            if "glibc-" in info.name and not info.name.endswith("-bin"):
                target_glibc = info.name
                glibc_local = is_local

            item_data = {
                "name": info.name,
                "hash": h,
                "store_path": sp,
                "file_size": info.file_size,
                "nar_size": info.nar_size,
                "is_local": is_local,
            }
            all_items.append(item_data)
            if is_local:
                local_items.append(item_data)
            else:
                missing_items.append(item_data)

        # 3. Calculate Totals
        gross_download = sum(item["file_size"] for item in all_items)
        gross_disk = sum(item["nar_size"] for item in all_items)

        net_download = sum(item["file_size"] for item in missing_items)
        net_disk = sum(item["nar_size"] for item in missing_items)

        saved_bandwidth = sum(item["file_size"] for item in local_items)
        saved_percent = (saved_bandwidth / gross_download * 100.0) if gross_download > 0 else 0.0
        local_percent = (len(local_items) / len(all_items) * 100.0) if all_items else 0.0

        closure_kwargs = {
            "target_name": target_name,
            "store_path": store_path,
            "version": version,
            "main_program": main_program,
            "cache_url": target_narinfo.source_cache_url,
            "compression": target_narinfo.compression or "xz",
            "file_size": target_narinfo.file_size,
            "nar_size": target_narinfo.nar_size,
            "total_refs": len(all_items),
            "local_count": len(local_items),
            "missing_count": len(missing_items),
            "target_glibc": target_glibc,
            "glibc_local": glibc_local,
            "target_is_local": target_is_local,
            "gross_download": gross_download,
            "gross_disk": gross_disk,
            "net_download": net_download,
            "net_disk": net_disk,
            "saved_bandwidth": saved_bandwidth,
            "saved_percent": saved_percent,
            "local_percent": local_percent,
            "missing_items": missing_items,
            "all_items": all_items,
        }
        if system:
            closure_kwargs["system"] = system

        return ClosureAudit(**closure_kwargs)

    def traverse_closure_for_download(
        self, store_name: str
    ) -> Tuple[Dict[str, NarInfo], List[DownloadItem]]:
        """Traverse a store name's closure and collect all missing NAR archives for download."""
        target_hash = store_name.split("-")[0]
        narinfos: Dict[str, NarInfo] = {}
        visited_hashes: Set[str] = set()
        queue = [target_hash]

        while queue:
            current_batch = queue
            queue = []
            to_fetch = []

            for h in current_batch:
                if h in visited_hashes:
                    continue
                visited_hashes.add(h)
                if h in self._shared_narinfos:
                    info = self._shared_narinfos[h]
                    narinfos[h] = info
                    for ref in info.references:
                        ref_hash = ref.split("-")[0]
                        if ref_hash not in visited_hashes:
                            queue.append(ref_hash)
                else:
                    to_fetch.append(h)

            if not to_fetch:
                continue

            with concurrent.futures.ThreadPoolExecutor(max_workers=self.client.max_workers) as executor:
                futures = {executor.submit(self.client.fetch_narinfo, h): h for h in to_fetch}
                for f in concurrent.futures.as_completed(futures):
                    h = futures[f]
                    info = f.result()
                    if info:
                        self._shared_narinfos[h] = info
                        narinfos[h] = info
                        for ref in info.references:
                            ref_hash = ref.split("-")[0]
                            if ref_hash not in visited_hashes:
                                queue.append(ref_hash)

        items_to_download: List[DownloadItem] = []
        for h, info in narinfos.items():
            sp = f"/nix/store/{info.name}" if not info.store_path else info.store_path
            if not is_path_in_nix_store(sp) and info.url:
                dl_url = (
                    f"{info.source_cache_url}/{info.url}"
                    if not info.url.startswith("http")
                    else info.url
                )
                filename = os.path.basename(info.url)
                items_to_download.append(
                    DownloadItem(
                        hash=h,
                        url=dl_url,
                        filename=filename,
                        file_size=info.file_size,
                        source_cache_url=info.source_cache_url,
                    )
                )

        return narinfos, items_to_download
