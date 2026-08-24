"""Nix Binary Cache HTTP client with multi-cache probing and concurrent DAG closure resolution."""
import concurrent.futures
import os
from pathlib import Path
import sys
import time
from typing import Any, Dict, List, Optional, Set, Tuple, Union
import urllib.error
import urllib.request

_scripts_dir = str(Path(__file__).resolve().parent)
if _scripts_dir not in sys.path:
    sys.path.insert(0, _scripts_dir)

from models import ClosureAudit, DownloadItem, NarInfo


class NixCacheClient:
    def __init__(
        self,
        cache_url: Union[str, List[str]] = "https://cache.nixos.org",
        max_workers: int = 16,
        timeout: float = 10.0,
        max_retries: int = 3,
    ):
        if isinstance(cache_url, str):
            raw_urls = [u.strip() for u in cache_url.replace(",", " ").split() if u.strip()]
            self.cache_urls = [u.rstrip("/") for u in raw_urls] if raw_urls else ["https://cache.nixos.org"]
        else:
            self.cache_urls = [u.rstrip("/") for u in cache_url] if cache_url else ["https://cache.nixos.org"]

        self.primary_cache_url = self.cache_urls[0]
        self.max_workers = max_workers
        self.timeout = timeout
        self.max_retries = max_retries
        self._narinfo_cache: Dict[str, Optional[NarInfo]] = {}

    @property
    def cache_url(self) -> str:
        return ", ".join(self.cache_urls)

    def _fetch_from_single_cache(self, base_url: str, hash_str: str) -> Optional[NarInfo]:
        url = f"{base_url}/{hash_str}.narinfo"
        req = urllib.request.Request(url, headers={"User-Agent": "NixCacheTools/1.0"})

        for attempt in range(self.max_retries):
            try:
                with urllib.request.urlopen(req, timeout=self.timeout) as resp:
                    raw_text = resp.read().decode("utf-8")
                    return self._parse_narinfo(hash_str, raw_text, base_url)
            except urllib.error.HTTPError as e:
                if e.code == 404:
                    return None
                if attempt == self.max_retries - 1:
                    return None
            except Exception:
                if attempt == self.max_retries - 1:
                    return None
            time.sleep(0.2 * (attempt + 1))
        return None

    def fetch_narinfo(self, hash_str: str) -> Optional[NarInfo]:
        """Fetch and parse .narinfo for a given store hash, probing all configured cache URLs."""
        if hash_str in self._narinfo_cache:
            return self._narinfo_cache[hash_str]

        for base_url in self.cache_urls:
            narinfo = self._fetch_from_single_cache(base_url, hash_str)
            if narinfo:
                self._narinfo_cache[hash_str] = narinfo
                return narinfo

        self._narinfo_cache[hash_str] = None
        return None

    def _parse_narinfo(self, hash_str: str, raw_text: str, base_url: str) -> NarInfo:
        store_path = ""
        url_rel = None
        compression = "none"
        file_size = 0
        nar_size = 0
        nar_hash = None
        references: List[str] = []

        for line in raw_text.splitlines():
            if line.startswith("StorePath:"):
                store_path = line.split(":", 1)[1].strip()
            elif line.startswith("URL:"):
                url_rel = line.split(":", 1)[1].strip()
            elif line.startswith("Compression:"):
                compression = line.split(":", 1)[1].strip()
            elif line.startswith("FileSize:"):
                try:
                    file_size = int(line.split(":", 1)[1].strip())
                except ValueError:
                    file_size = 0
            elif line.startswith("NarSize:"):
                try:
                    nar_size = int(line.split(":", 1)[1].strip())
                except ValueError:
                    nar_size = 0
            elif line.startswith("NarHash:"):
                nar_hash = line.split(":", 1)[1].strip()
            elif line.startswith("References:"):
                references = line[len("References:"):].strip().split()

        name = os.path.basename(store_path) if store_path else f"{hash_str}-unknown"
        return NarInfo(
            store_path=store_path,
            hash=hash_str,
            name=name,
            url=url_rel,
            compression=compression,
            file_size=file_size,
            nar_size=nar_size,
            nar_hash=nar_hash,
            references=references,
            raw_text=raw_text,
            source_cache_url=base_url,
        )

    def check_hit(self, hash_str: str) -> bool:
        """Quick check if a narinfo exists on any configured cache server."""
        for base_url in self.cache_urls:
            url = f"{base_url}/{hash_str}.narinfo"
            req = urllib.request.Request(url, method="HEAD", headers={"User-Agent": "NixCacheTools/1.0"})
            try:
                with urllib.request.urlopen(req, timeout=self.timeout) as resp:
                    if resp.status == 200:
                        return True
            except Exception:
                continue
        return False

    def traverse_closure_for_download(
        self, root_name: str
    ) -> Tuple[Dict[str, NarInfo], List[DownloadItem]]:
        """Traverse the closure DAG starting from root_name, collecting all NarInfos and missing DownloadItems."""
        visited_hashes: Set[str] = set()
        narinfos: Dict[str, NarInfo] = {}
        items_to_download: List[DownloadItem] = []

        queue = [root_name]

        while queue:
            current_batch = list(queue)
            queue = []

            hashes_to_fetch = []
            for name in current_batch:
                h = name.split("-")[0]
                if h not in visited_hashes:
                    visited_hashes.add(h)
                    hashes_to_fetch.append((h, name))

            if not hashes_to_fetch:
                continue

            with concurrent.futures.ThreadPoolExecutor(max_workers=self.max_workers) as executor:
                future_to_item = {
                    executor.submit(self.fetch_narinfo, h): (h, name) for h, name in hashes_to_fetch
                }
                for future in concurrent.futures.as_completed(future_to_item):
                    h, name = future_to_item[future]
                    try:
                        narinfo = future.result()
                    except Exception:
                        narinfo = None

                    if not narinfo:
                        print(
                            f"⚠️ Warning: Gagal mengunduh metadata .narinfo untuk hash {h}",
                            file=sys.stderr,
                        )
                        continue

                    narinfos[h] = narinfo

                    # If not locally present in /nix/store/<name> and has url
                    if narinfo.url and not os.path.exists(f"/nix/store/{name}"):
                        items_to_download.append(
                            DownloadItem(
                                hash=h,
                                url=f"{narinfo.source_cache_url}/{narinfo.url}",
                                filename=os.path.basename(narinfo.url),
                                file_size=narinfo.file_size,
                                source_cache_url=narinfo.source_cache_url,
                            )
                        )

                    for r in narinfo.references:
                        r_hash = r.split("-")[0]
                        if r_hash not in visited_hashes:
                            queue.append(r)

        return narinfos, items_to_download

    def audit_closure(
        self,
        target_name: str,
        store_path: str,
        version: str,
        main_program: Optional[str],
    ) -> ClosureAudit:
        """Perform comprehensive gross vs net analysis of the target store path closure."""
        root_hash = os.path.basename(store_path).split("-")[0]
        root_name = os.path.basename(store_path)

        root_narinfo = self.fetch_narinfo(root_hash)
        if not root_narinfo:
            raise RuntimeError(f"Store path tidak ditemukan di {self.cache_url}: {store_path}")

        visited_hashes: Set[str] = {root_hash}
        all_deps: Dict[str, Dict[str, Any]] = {}

        queue = [r for r in root_narinfo.references if r != root_name]

        while queue:
            current_items = list(queue)
            queue = []

            hashes_to_fetch = []
            for item in current_items:
                h = item.split("-")[0]
                if h not in visited_hashes:
                    visited_hashes.add(h)
                    hashes_to_fetch.append((h, item))

            if not hashes_to_fetch:
                continue

            with concurrent.futures.ThreadPoolExecutor(max_workers=self.max_workers) as executor:
                future_to_item = {
                    executor.submit(self.fetch_narinfo, h): (h, item) for h, item in hashes_to_fetch
                }
                for future in concurrent.futures.as_completed(future_to_item):
                    h, name = future_to_item[future]
                    try:
                        narinfo = future.result()
                    except Exception:
                        narinfo = None

                    is_local = os.path.exists(f"/nix/store/{name}")
                    fs = narinfo.file_size if narinfo else 0
                    ns = narinfo.nar_size if narinfo else 0
                    refs = narinfo.references if narinfo else []

                    all_deps[name] = {
                        "name": name,
                        "file_size": fs,
                        "nar_size": ns,
                        "is_local": is_local,
                    }

                    for r in refs:
                        r_hash = r.split("-")[0]
                        if r_hash not in visited_hashes:
                            queue.append(r)

        all_meta = list(all_deps.values())
        total_refs = len(all_meta)
        local_refs = [m for m in all_meta if m["is_local"]]
        missing_refs = [m for m in all_meta if not m["is_local"]]

        target_glibc = "None (Static / Independent)"
        glibc_local = False
        for name in all_deps:
            if "-glibc-" in name or "-glibc_" in name:
                target_glibc = name
                glibc_local = all_deps[name]["is_local"]
                break

        # Check if root target itself is already present locally
        target_is_local = os.path.exists(f"/nix/store/{root_name}")
        root_download_needed = 0 if target_is_local else root_narinfo.file_size
        root_disk_needed = 0 if target_is_local else root_narinfo.nar_size

        gross_libs_download = sum(m["file_size"] for m in all_meta)
        gross_libs_disk = sum(m["nar_size"] for m in all_meta)
        missing_download = sum(m["file_size"] for m in missing_refs)
        missing_disk = sum(m["nar_size"] for m in missing_refs)

        gross_download = root_narinfo.file_size + gross_libs_download
        gross_disk = root_narinfo.nar_size + gross_libs_disk
        net_download = root_download_needed + missing_download
        net_disk = root_disk_needed + missing_disk

        saved_bandwidth = gross_download - net_download
        saved_percent = (saved_bandwidth / gross_download * 100.0) if gross_download > 0 else 0.0
        local_percent = (len(local_refs) / total_refs * 100.0) if total_refs > 0 else 100.0

        all_meta.sort(key=lambda x: x["name"])
        missing_refs.sort(key=lambda x: x["name"])

        return ClosureAudit(
            target_name=target_name,
            store_path=store_path,
            version=version,
            main_program=main_program,
            cache_url=root_narinfo.source_cache_url,
            compression=root_narinfo.compression or "none",
            file_size=root_narinfo.file_size,
            nar_size=root_narinfo.nar_size,
            total_refs=total_refs,
            local_count=len(local_refs),
            missing_count=len(missing_refs),
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
            missing_items=missing_refs,
            all_items=all_meta,
        )
