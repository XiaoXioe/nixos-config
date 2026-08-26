"""Nix closure DAG traversal, local store auditing, and bandwidth calculation."""
import concurrent.futures
import os
import re
from typing import Any, Dict, List, Optional, Set, Tuple

from core.cache_client import NixCacheClient
from core.models import ClosureAudit, DownloadItem, NarInfo
from core.nix_eval import is_path_in_nix_store


class ClosureAuditor:
    """Performs DAG closure resolution, dependency tree traversal, and local store comparison."""

    def __init__(self, cache_client: NixCacheClient):
        self.client = cache_client

    def audit_closure(
        self,
        target_name: str,
        store_path: str,
        version: str = "",
        main_program: Optional[str] = None,
    ) -> ClosureAudit:
        """Analyze a store path's full closure, local reuse percentage, and bandwidth savings."""
        target_hash = os.path.basename(store_path).split("-")[0]
        target_narinfo = self.client.fetch_narinfo(target_hash)

        if not target_narinfo:
            raise RuntimeError(
                f"Biner untuk store path {store_path} tidak ditemukan di binary cache ({self.client.summary_display}).\n"
                "💡 Catatan: Paket berlisensi 'unfree' (proprietary) atau paket kustom umumnya tidak di-build/di-cache oleh server Hydra resmi (cache.nixos.org)."
            )

        # 1. Traverse closure DAG
        visited_hashes: Set[str] = set()
        queue = [target_hash]
        narinfos: Dict[str, NarInfo] = {}

        while queue:
            current_batch = queue
            queue = []
            to_fetch = [h for h in current_batch if h not in visited_hashes and h not in narinfos]
            visited_hashes.update(to_fetch)

            if not to_fetch:
                continue

            with concurrent.futures.ThreadPoolExecutor(max_workers=self.client.max_workers) as executor:
                futures = {executor.submit(self.client.fetch_narinfo, h): h for h in to_fetch}
                for f in concurrent.futures.as_completed(futures):
                    h = futures[f]
                    info = f.result()
                    if info:
                        narinfos[h] = info
                        for ref in info.references:
                            ref_hash = ref.split("-")[0]
                            if ref_hash not in visited_hashes and ref_hash not in narinfos:
                                queue.append(ref_hash)

        # 2. Local vs Missing Partitioning
        local_items: List[Dict[str, Any]] = []
        missing_items: List[Dict[str, Any]] = []
        all_items: List[Dict[str, Any]] = []

        target_glibc = "Unknown"
        glibc_local = False
        target_is_local = is_path_in_nix_store(store_path)

        for h, info in narinfos.items():
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

        return ClosureAudit(
            target_name=target_name,
            store_path=store_path,
            version=version,
            main_program=main_program,
            cache_url=target_narinfo.source_cache_url,
            compression=target_narinfo.compression or "xz",
            file_size=target_narinfo.file_size,
            nar_size=target_narinfo.nar_size,
            total_refs=len(all_items),
            local_count=len(local_items),
            missing_count=len(missing_items),
            target_glibc=target_glibc,
            glibc_local=glibc_local,
            target_is_local=target_is_local,
            gross_download=gross_download,
            gross_disk=gross_disk,
            net_download=net_download,
            net_disk=net_disk,
            saved_bandwidth=saved_bandwidth,
            saved_percent=saved_percent,
            local_percent=local_percent,
            missing_items=missing_items,
            all_items=all_items,
        )

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
            to_fetch = [h for h in current_batch if h not in visited_hashes and h not in narinfos]
            visited_hashes.update(to_fetch)

            if not to_fetch:
                continue

            with concurrent.futures.ThreadPoolExecutor(max_workers=self.client.max_workers) as executor:
                futures = {executor.submit(self.client.fetch_narinfo, h): h for h in to_fetch}
                for f in concurrent.futures.as_completed(futures):
                    h = futures[f]
                    info = f.result()
                    if info:
                        narinfos[h] = info
                        for ref in info.references:
                            ref_hash = ref.split("-")[0]
                            if ref_hash not in visited_hashes and ref_hash not in narinfos:
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
