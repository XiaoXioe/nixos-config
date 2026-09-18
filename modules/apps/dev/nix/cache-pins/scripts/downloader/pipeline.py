"""Streaming Download & Reactive Ingestion Pipeline for nix-cache-pin (ncp).

Enables instant, concurrent ingestion of downloaded NAR and FOD archives into /nix/store
as soon as each file arrives from aria2c, maintaining an ultra-low RAM footprint by
cleaning up archives immediately from RAM tmpfs (Zero SSD Wear).
"""

import collections
import os
from pathlib import Path
import shutil
import subprocess
import sys
import threading
import time
from typing import Dict, List, Optional, Set, Tuple, Union

from core.cache_client import NixCacheClient
from core.eval.resolver import is_path_in_nix_store
from core.models import DownloadItem, FodDownloadItem, NarInfo
from downloader.aria2 import launch_aria2_process
from downloader.ingest import ingest_single_fod, ingest_store_paths
from ui.formatters import format_bytes


class DAGResolver:
    """Dependency graph analyzer and topological sorter for Nix store path closures."""

    @staticmethod
    def build_dag(
        narinfos: Dict[str, NarInfo],
        already_valid_paths: Set[str],
    ) -> Tuple[Dict[str, Set[str]], Dict[str, Set[str]]]:
        """Build forward (missing dependencies) and reverse (dependents) DAG mappings.

        Returns:
            unresolved_deps: Dict[store_path, Set[missing_dependency_store_paths]]
            reverse_deps: Dict[dependency_store_path, Set[dependent_store_paths]]
        """
        unresolved_deps: Dict[str, Set[str]] = {}
        reverse_deps: Dict[str, Set[str]] = collections.defaultdict(set)

        for info in narinfos.values():
            sp = info.store_path or f"/nix/store/{info.name}"
            if sp in already_valid_paths:
                continue

            missing = set()
            for ref in info.references:
                ref_sp = f"/nix/store/{ref}" if not ref.startswith("/nix/store/") else ref
                if ref_sp != sp and ref_sp not in already_valid_paths:
                    missing.add(ref_sp)
                    reverse_deps[ref_sp].add(sp)

            unresolved_deps[sp] = missing

        return unresolved_deps, dict(reverse_deps)

    @classmethod
    def topological_sort(
        cls,
        download_items: List[DownloadItem],
        narinfos: Dict[str, NarInfo],
        fod_items: Optional[List[FodDownloadItem]] = None,
        already_valid_paths: Optional[Set[str]] = None,
    ) -> List[DownloadItem]:
        """Sort download items in bottom-up DAG topological order (leaves and dependencies first).

        FOD items (source archives / tarballs) are prioritized at level 0 since they have
        no store path references and can ingest immediately.
        """
        valid_paths = already_valid_paths or set()
        unresolved_deps, _ = cls.build_dag(narinfos, valid_paths)

        # Map store paths to DAG level
        levels: Dict[str, int] = {}
        # Items with 0 missing dependencies are level 0
        current_level = 0
        pending = dict(unresolved_deps)

        resolved_in_sort = set(valid_paths)

        while pending:
            newly_resolved = []
            for sp, deps in list(pending.items()):
                if deps.issubset(resolved_in_sort):
                    levels[sp] = current_level
                    newly_resolved.append(sp)
                    del pending[sp]

            if not newly_resolved:
                # Cycle or unresolved external dependency fallback
                for sp in pending:
                    levels[sp] = current_level
                break

            resolved_in_sort.update(newly_resolved)
            current_level += 1

        # Map DownloadItem to its store_path
        hash_to_sp: Dict[str, str] = {}
        for h, info in narinfos.items():
            sp = info.store_path or f"/nix/store/{info.name}"
            hash_to_sp[h] = sp
            if info.nar_hash:
                hash_to_sp[info.nar_hash] = sp

        fod_keys = set()
        if fod_items:
            for f in fod_items:
                fod_keys.add(f.filename)
                fod_keys.add(f.out_path)
                if getattr(f, "download_filename", None):
                    fod_keys.add(f.download_filename)

        def get_item_sort_key(item: DownloadItem) -> Tuple[int, int]:
            # FOD items get level -1 (highest priority)
            if item.filename in fod_keys or item.hash in fod_keys:
                return (-1, item.file_size)

            sp = hash_to_sp.get(item.hash)
            if not sp:
                # Fallback: check basename matches
                for s in levels:
                    if s.endswith(item.filename.split(".")[0]):
                        sp = s
                        break

            level = levels.get(sp, current_level + 1) if sp else current_level + 1
            # Sort by level ascending, then file size ascending (fast leaves first)
            return (level, item.file_size)

        return sorted(download_items, key=get_item_sort_key)


class StreamingIngestPipeline:
    """Manages streaming download via aria2c and concurrent reactive ingestion into /nix/store."""

    def __init__(
        self,
        cache_client: NixCacheClient,
        local_cache_dir: Union[str, Path],
        concurrent: int = 4,
        split: int = 8,
        keep_nar: bool = False,
        verbose: bool = False,
    ):
        self.cache_client = cache_client
        self.local_cache_dir = Path(local_cache_dir).resolve()
        self.nar_dir = self.local_cache_dir / "nar"
        self.concurrent = concurrent
        self.split = split
        self.keep_nar = keep_nar
        self.verbose = verbose

    def run(
        self,
        download_items: List[DownloadItem],
        narinfos: Dict[str, NarInfo],
        fod_items: Optional[List[FodDownloadItem]] = None,
    ) -> bool:
        """Execute the streaming download and ingestion pipeline."""
        if not download_items:
            return True

        self.local_cache_dir.mkdir(parents=True, exist_ok=True)
        self.nar_dir.mkdir(parents=True, exist_ok=True)

        # 1. Setup lookup maps
        filename_to_store_paths: Dict[str, List[str]] = collections.defaultdict(list)
        store_path_to_filename: Dict[str, str] = {}
        filename_to_fod: Dict[str, FodDownloadItem] = {}

        for info in narinfos.values():
            sp = info.store_path or f"/nix/store/{info.name}"
            if info.url:
                fn = os.path.basename(info.url)
                filename_to_store_paths[fn].append(sp)
                store_path_to_filename[sp] = fn

        if fod_items:
            for fod in fod_items:
                fn = getattr(fod, "download_filename", None) or fod.filename
                filename_to_fod[fn] = fod
                if getattr(fod, "out_path", None):
                    out_hash = fod.out_path.split("/")[-1].split("-")[0]
                    filename_to_fod[out_hash] = fod
                    filename_to_fod[out_hash[:10]] = fod

        # 2. Check paths already valid in /nix/store
        all_store_paths = list(store_path_to_filename.keys())
        already_valid_paths: Set[str] = set()
        for sp in all_store_paths:
            if is_path_in_nix_store(sp):
                already_valid_paths.add(sp)

        # 3. Build DAG and sort items topologically
        unresolved_deps, reverse_deps = DAGResolver.build_dag(narinfos, already_valid_paths)
        sorted_items = DAGResolver.topological_sort(
            download_items,
            narinfos,
            fod_items=fod_items,
            already_valid_paths=already_valid_paths,
        )

        # 4. Clean up any leftover orphan files in nar_dir that do not belong to this batch
        if self.nar_dir.exists():
            batch_filenames = {item.filename for item in sorted_items}
            for p in self.nar_dir.iterdir():
                if p.is_file():
                    base_name = p.name[:-6] if p.name.endswith(".aria2") else p.name
                    if base_name not in batch_filenames:
                        try:
                            p.unlink(missing_ok=True)
                        except Exception:
                            pass

        # 5. Write aria2 batch file
        aria2_batch_file = self.local_cache_dir / "aria2_batch.txt"
        written_filenames = set()
        with open(aria2_batch_file, "w", encoding="utf-8") as f:
            for item in sorted_items:
                if item.filename in written_filenames:
                    continue
                written_filenames.add(item.filename)
                f.write(f"{item.url}\n")
                f.write(f"  dir={self.nar_dir}\n")
                f.write(f"  out={item.filename}\n")

        # 5. Create aria2 completion hook script and log
        completed_log = self.local_cache_dir / "completed_downloads.log"
        if completed_log.exists():
            completed_log.unlink()
        completed_log.touch()

        hook_script = self.local_cache_dir / "on_download_complete.sh"
        hook_script.write_text(
            f"#!/bin/sh\nprintf '%s\\n' \"$3\" >> \"{completed_log}\"\n"
        )
        os.chmod(hook_script, 0o755)

        # 6. Pipeline state
        ingested_paths: Set[str] = set(already_valid_paths)
        downloaded_files: Set[str] = set()
        waiting_queue: Dict[str, Set[str]] = {}
        ready_queue: collections.deque = collections.deque()
        failed_items: List[str] = []

        total_to_ingest = len(all_store_paths) + len(fod_items or [])
        ingested_count = 0
        total_freed_bytes = 0

        state_lock = threading.Lock()
        stop_worker = threading.Event()
        aria2_finished = threading.Event()

        def try_enqueue_downloaded_file(fname: str):
            nonlocal ingested_count, total_freed_bytes
            # A. Check if FOD item
            fod = filename_to_fod.get(fname)
            if not fod and fod_items:
                for f in fod_items:
                    out_h = f.out_path.split("/")[-1].split("-")[0] if getattr(f, "out_path", None) else ""
                    dl_fn = getattr(f, "download_filename", None) or f.filename
                    if (out_h and (out_h in fname or out_h[:10] in fname)) or dl_fn == fname:
                        fod = f
                        break

            if fod:
                ok = ingest_single_fod(fod, self.nar_dir, delete_after=not self.keep_nar)
                if ok:
                    ingested_count += 1
                    print(
                        f"\r\033[K  ✔ [Ingest FOD {ingested_count}/{total_to_ingest}] {fod.filename} ➔ {fod.out_path}",
                        file=sys.stderr,
                    )
                else:
                    failed_items.append(fod.filename)
                return

            # B. Check if NAR package
            if fname in filename_to_store_paths:
                for sp in filename_to_store_paths[fname]:
                    if sp in ingested_paths:
                        continue

                    deps = unresolved_deps.get(sp, set())
                    remaining = {d for d in deps if d not in ingested_paths}
                    if not remaining:
                        ready_queue.append(sp)
                    else:
                        waiting_queue[sp] = remaining

        def drain_ready_queue():
            nonlocal ingested_count, total_freed_bytes
            while True:
                with state_lock:
                    if not ready_queue:
                        break
                    # Batch up to 8 ready store paths for fast atomic ingestion
                    batch: List[str] = []
                    while ready_queue and len(batch) < 8:
                        batch.append(ready_queue.popleft())

                # Execute fast nix copy
                ok = ingest_store_paths(batch, self.local_cache_dir, self.cache_client.cache_urls)

                with state_lock:
                    if ok:
                        for sp in batch:
                            ingested_paths.add(sp)
                            ingested_count += 1

                            # Immediate RAM tmpfs cleanup (Zero SSD Wear & Ultra-low RAM footprint)
                            freed_str = ""
                            if not self.keep_nar:
                                nar_fn = store_path_to_filename.get(sp)
                                if nar_fn:
                                    users = filename_to_store_paths.get(nar_fn, [])
                                    if all(u in ingested_paths for u in users):
                                        nar_p = self.nar_dir / nar_fn
                                        if nar_p.exists():
                                            try:
                                                sz = nar_p.stat().st_size
                                                nar_p.unlink(missing_ok=True)
                                                total_freed_bytes += sz
                                                freed_str = f" [RAM bebas: +{format_bytes(sz)}]"
                                            except Exception:
                                                pass

                            pkg_name = os.path.basename(sp)
                            print(
                                f"\r\033[K  ✔ [Ingest {ingested_count}/{total_to_ingest}] {pkg_name}{freed_str}",
                                file=sys.stderr,
                            )

                            # Unblock dependents in waiting_queue
                            dependents = reverse_deps.get(sp, set())
                            for dep_sp in list(dependents):
                                if dep_sp in waiting_queue:
                                    waiting_queue[dep_sp].discard(sp)
                                    if not waiting_queue[dep_sp]:
                                        del waiting_queue[dep_sp]
                                        ready_queue.append(dep_sp)
                    else:
                        for sp in batch:
                            failed_items.append(sp)

        def worker_loop():
            # Open completed_log for streaming read
            with open(completed_log, "r", encoding="utf-8") as f:
                while not stop_worker.is_set():
                    line = f.readline()
                    if not line:
                        if aria2_finished.is_set():
                            # Aria2 is done, check if any pending items remain
                            with state_lock:
                                if not ready_queue:
                                    break
                        time.sleep(0.05)
                        continue

                    raw_path = line.strip()
                    if not raw_path:
                        continue

                    fname = os.path.basename(raw_path)
                    with state_lock:
                        if fname in downloaded_files:
                            continue
                        downloaded_files.add(fname)
                        try_enqueue_downloaded_file(fname)

                    drain_ready_queue()

                # Final drain
                drain_ready_queue()

        # 7. Start worker thread
        worker_thread = threading.Thread(
            target=worker_loop, name="ReactiveIngestWorker", daemon=True
        )
        worker_thread.start()

        # 8. Launch aria2c process
        aria2_proc = launch_aria2_process(
            batch_file_path=aria2_batch_file,
            nar_dir=self.nar_dir,
            concurrent=self.concurrent,
            split=self.split,
            on_download_complete=str(hook_script),
        )

        try:
            rc = aria2_proc.wait()
        except KeyboardInterrupt:
            print("\n⚠️ Unduhan dibatalkan oleh pengguna (SIGINT)...", file=sys.stderr)
            aria2_proc.terminate()
            try:
                aria2_proc.wait(timeout=3)
            except subprocess.TimeoutExpired:
                aria2_proc.kill()
            stop_worker.set()
            worker_thread.join(timeout=2)
            sys.exit(130)

        # 9. Signal completion and join worker
        aria2_finished.set()
        worker_thread.join(timeout=30)
        if worker_thread.is_alive():
            stop_worker.set()
            worker_thread.join(timeout=5)

        # 10. Post-download Sweep (Catch any files aria2c hook might have missed)
        if rc == 0:
            with state_lock:
                for item in sorted_items:
                    fn = item.filename
                    if fn not in downloaded_files:
                        p = self.nar_dir / fn
                        aria_ctl = self.nar_dir / f"{fn}.aria2"
                        if p.exists() and not aria_ctl.exists():
                            downloaded_files.add(fn)
                            try_enqueue_downloaded_file(fn)

            # If any remaining items in waiting_queue, try ingesting them in the final pass
            with state_lock:
                if waiting_queue:
                    for sp in list(waiting_queue.keys()):
                        ready_queue.append(sp)
                    waiting_queue.clear()

            drain_ready_queue()

        # 11. Cleanup hook artifacts
        try:
            if hook_script.exists():
                hook_script.unlink()
            if completed_log.exists():
                completed_log.unlink()
        except Exception:
            pass

        if total_freed_bytes > 0:
            print(
                f"💾 Total RAM tmpfs yang langsung dibebaskan selama proses: {format_bytes(total_freed_bytes)}",
                file=sys.stderr,
            )

        if rc != 0:
            print(f"❌ ERROR: aria2c gagal dengan kode keluar {rc}.", file=sys.stderr)
            return False

        if failed_items:
            print(
                f"❌ ERROR: Terdapat {len(failed_items)} item yang gagal di-ingest ke /nix/store.",
                file=sys.stderr,
            )
            return False

        return True
