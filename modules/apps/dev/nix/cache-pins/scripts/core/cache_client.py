"""Nix Binary Cache HTTP client with multi-cache probing and hit detection."""
import concurrent.futures
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time
from typing import Any, Dict, List, Optional, Set, Tuple, Union
import urllib.error
import urllib.request

from core.models import NarInfo


def get_system_substituters() -> List[str]:
    """Auto-detect configured substituters from nix config (substituters + extra-substituters)."""
    caches: List[str] = []

    # 1. Environment variable CACHE_URL
    env_cache = os.environ.get("CACHE_URL")
    if env_cache:
        for u in env_cache.replace(",", " ").split():
            clean = re.sub(r"\?.*$", "", u.strip()).rstrip("/")
            if clean and clean not in caches:
                caches.append(clean)
        if caches:
            return caches

    # 2. Query nix configuration
    try:
        res = subprocess.run(
            ["nix", "config", "show", "--json"],
            capture_output=True,
            text=True,
            timeout=5,
        )
        if res.returncode == 0:
            data = json.loads(res.stdout)
            substituters = data.get("substituters", {}).get("value", [])
            extra = data.get("extra-substituters", {}).get("value", [])
            all_subs = substituters + extra
            for s in all_subs:
                clean = re.sub(r"\?.*$", "", s.strip()).rstrip("/")
                if clean and clean.startswith("http") and clean not in caches:
                    caches.append(clean)
    except Exception:
        pass

    if not caches:
        caches = ["https://cache.nixos.org"]
    return caches


class NixCacheClient:
    """High-performance HTTP client for probing Nix binary caches with retry and fallback."""

    def __init__(
        self,
        cache_url: Optional[Union[str, List[str]]] = None,
        max_workers: int = 16,
        timeout: float = 10.0,
        max_retries: int = 3,
    ):
        if cache_url is None:
            self.cache_urls = get_system_substituters()
        elif isinstance(cache_url, str):
            raw_urls = [u.strip() for u in cache_url.replace(",", " ").split() if u.strip()]
            cleaned = []
            for u in raw_urls:
                c = re.sub(r"\?.*$", "", u).rstrip("/")
                if c and c not in cleaned:
                    cleaned.append(c)
            self.cache_urls = cleaned if cleaned else get_system_substituters()
        else:
            cleaned = []
            for u in cache_url:
                c = re.sub(r"\?.*$", "", u.strip()).rstrip("/")
                if c and c not in cleaned:
                    cleaned.append(c)
            self.cache_urls = cleaned if cleaned else get_system_substituters()

        self.primary_cache_url = self.cache_urls[0]
        self.max_workers = max_workers
        self.timeout = timeout
        self.max_retries = max_retries
        self._narinfo_cache: Dict[str, Optional[NarInfo]] = {}

    @property
    def cache_url(self) -> str:
        """Comma-separated string of all configured binary caches."""
        return ", ".join(self.cache_urls)

    @property
    def summary_display(self) -> str:
        """Concise string representing configured binary caches for CLI output."""
        if len(self.cache_urls) <= 2:
            return ", ".join(self.cache_urls)
        return f"{self.cache_urls[0]} (+ {len(self.cache_urls) - 1} binary caches)"

    def _fetch_from_single_cache(self, base_url: str, hash_str: str) -> Optional[NarInfo]:
        url = f"{base_url}/{hash_str}.narinfo"
        req = urllib.request.Request(url, headers={"User-Agent": "NixCacheTools/1.0"})

        for attempt in range(self.max_retries):
            try:
                with urllib.request.urlopen(req, timeout=self.timeout) as resp:
                    if resp.status == 200:
                        content = resp.read().decode("utf-8")
                        return self._parse_narinfo(content, hash_str, source_cache_url=base_url)
            except urllib.error.HTTPError as e:
                if e.code == 404:
                    return None
            except (urllib.error.URLError, TimeoutError):
                if attempt < self.max_retries - 1:
                    time.sleep(0.3 * (2**attempt))
            except Exception:
                pass
        return None

    def fetch_narinfo(self, hash_str: str) -> Optional[NarInfo]:
        """Fetch NarInfo for a store hash across all configured caches."""
        if hash_str in self._narinfo_cache:
            return self._narinfo_cache[hash_str]

        # 1. Coba cache utama
        info = self._fetch_from_single_cache(self.primary_cache_url, hash_str)
        if info:
            self._narinfo_cache[hash_str] = info
            return info

        # 2. Coba cache sekunder secara paralel
        secondary_urls = self.cache_urls[1:]
        if secondary_urls:
            with concurrent.futures.ThreadPoolExecutor(max_workers=len(secondary_urls)) as executor:
                futures = {
                    executor.submit(self._fetch_from_single_cache, url, hash_str): url
                    for url in secondary_urls
                }
                for f in concurrent.futures.as_completed(futures):
                    res = f.result()
                    if res:
                        self._narinfo_cache[hash_str] = res
                        return res

        self._narinfo_cache[hash_str] = None
        return None

    def check_hit(self, hash_str: str) -> bool:
        """Check whether a given store hash is available (HIT) in any binary cache."""
        return self.fetch_narinfo(hash_str) is not None

    def _parse_narinfo(self, text: str, default_hash: str, source_cache_url: str) -> NarInfo:
        store_path = ""
        url = None
        compression = None
        file_size = 0
        nar_size = 0
        nar_hash = None
        references: List[str] = []

        for line in text.strip().split("\n"):
            if ": " in line:
                k, v = line.split(": ", 1)
                k = k.strip()
                v = v.strip()
                if k == "StorePath":
                    store_path = v
                elif k == "URL":
                    url = v
                elif k == "Compression":
                    compression = v
                elif k == "FileSize":
                    try:
                        file_size = int(v)
                    except ValueError:
                        pass
                elif k == "NarSize":
                    try:
                        nar_size = int(v)
                    except ValueError:
                        pass
                elif k == "NarHash":
                    nar_hash = v
                elif k == "References":
                    references = [r.strip() for r in v.split() if r.strip()]

        name = os.path.basename(store_path) if store_path else default_hash
        return NarInfo(
            store_path=store_path,
            hash=default_hash,
            name=name,
            url=url,
            compression=compression,
            file_size=file_size,
            nar_size=nar_size,
            nar_hash=nar_hash,
            references=references,
            raw_text=text,
            source_cache_url=source_cache_url,
        )
