from concurrent.futures import ThreadPoolExecutor, as_completed
import os
import sys
from pathlib import Path
from typing import List, Optional

from core.cache_client import NixCacheClient
from core.closure import ClosureAuditor
from core.models import DownloadItem, FodDownloadItem
from core.eval.system_eval import extract_missing_fods
from core.nix_eval import (
    evaluate_system_missing_paths,
    find_cache_pins_file,
    find_flake_dir,
    get_system_hostname,
    is_path_in_nix_store,
    resolve_target_to_store_path,
)
from downloader.aria2 import (
    ensure_aria2_installed,
    generate_aria2_batch_file,
    run_aria2_download,
)
from downloader.ingest import ingest_fod_items, ingest_store_paths
from downloader.pipeline import StreamingIngestPipeline
from downloader.ram_cache import (
    cleanup_ram_cache,
    get_default_ram_cache_dir,
    setup_ram_cache_dir,
)
from registry.audit import find_unused_pins
from registry.store import load_cache_pins
from ui.formatters import format_bytes


def download_single_target(
    target_input: str,
    cache_client: NixCacheClient,
    nixpkgs_input: str = "nixpkgs",
    pins_file_path: Optional[str] = None,
    cache_dir: Optional[str] = None,
    split: int = 8,
    concurrent: int = 4,
    keep_nar: bool = False,
    explicit_input: bool = False,
    verbose: bool = False,
    dry_run: bool = False,
):
    """Download and ingest a single package and its complete closure into /nix/store."""
    ensure_aria2_installed()

    pins_file = find_cache_pins_file(pins_file_path)
    local_cache_dir = Path(cache_dir or get_default_ram_cache_dir()).resolve()

    # 1. Resolusi Target
    try:
        store_path, _, _ = resolve_target_to_store_path(
            target=target_input,
            nixpkgs_input=nixpkgs_input,
            pins_file=pins_file,
            prefer_pin=True,
            explicit_input=explicit_input,
        )
    except Exception as e:
        print(f"❌ ERROR: {e}", file=sys.stderr)
        sys.exit(1)

    store_name = os.path.basename(store_path)

    print(
        "================================================================================",
        file=sys.stderr,
    )
    print(f"📦 Target Package       : {store_name}", file=sys.stderr)
    print(f"🔗 Store Path           : {store_path}", file=sys.stderr)
    print(
        f"💾 Penyimpanan Unduhan  : RAM (tmpfs: {local_cache_dir}) [Zero SSD Wear]",
        file=sys.stderr,
    )
    print(
        "================================================================================",
        file=sys.stderr,
    )

    # 2. Cek Apakah Path Sudah Ada di /nix/store
    if is_path_in_nix_store(store_path):
        print(
            "✅ Path sudah ada dan terdaftar secara valid di /nix/store!",
            file=sys.stderr,
        )
        print(
            "   Tidak memerlukan unduhan internet (0 Byte overhead).", file=sys.stderr
        )
        sys.exit(0)

    # 3. Setup RAM tmpfs
    local_cache_dir, nar_dir = setup_ram_cache_dir(local_cache_dir)

    # 4. Scan missing dependencies
    print(
        f"🌐 [1/3] Memeriksa pohon dependensi closure dari binary cache ({cache_client.summary_display})...",
        file=sys.stderr,
    )
    auditor = ClosureAuditor(cache_client)
    narinfos, items_to_download = auditor.traverse_closure_for_download(store_name)

    total_items = len(items_to_download)
    total_size_bytes = sum(item.file_size for item in items_to_download)
    print(
        f"📋 Ditemukan {total_items} paket closure yang perlu diunduh (Total: {format_bytes(total_size_bytes)})",
        file=sys.stderr,
    )

    if dry_run:
        if items_to_download:
            print("\n[DRY RUN] Biner closure yang perlu diunduh:", file=sys.stderr)
            for item in items_to_download:
                print(
                    f"   - {item.filename} ({format_bytes(item.file_size)})",
                    file=sys.stderr,
                )
        print(
            "\n(Mode dry-run: Tidak ada biner yang diunduh atau di-ingest)",
            file=sys.stderr,
        )
        sys.exit(0)

    for h, info in narinfos.items():
        (local_cache_dir / f"{h}.narinfo").write_text(info.raw_text)

    # 5. Streaming Download ke RAM & Reactive Ingestion ke /nix/store
    if total_items > 0:
        print("", file=sys.stderr)
        print(
            f"🚀 [2/3] Streaming download & instant ingestion ({total_items} paket) via aria2c + nix copy ({split} koneksi):",
            file=sys.stderr,
        )
        print(
            "--------------------------------------------------------------------------------",
            file=sys.stderr,
        )
        pipeline = StreamingIngestPipeline(
            cache_client=cache_client,
            local_cache_dir=local_cache_dir,
            concurrent=concurrent,
            split=split,
            keep_nar=keep_nar,
            verbose=verbose,
        )
        ok = pipeline.run(download_items=items_to_download, narinfos=narinfos)
        if not ok:
            print(
                f"❌ ERROR: Unduhan atau ingest streaming untuk {store_path} gagal.",
                file=sys.stderr,
            )
            sys.exit(1)

    # 6. Cleanup sisa cache jika keep_nar=False
    if not keep_nar:
        cleanup_ram_cache(nar_dir)
        print(
            "🧹 RAM Cache (.nar archives) otomatis dibersihkan (Zero SSD Wear).",
            file=sys.stderr,
        )

    print(
        "================================================================================",
        file=sys.stderr,
    )
    print(
        "🎉 SUKSES! Biner & seluruh library berhasil di-ingest ke /nix/store:",
        file=sys.stderr,
    )
    print(f"   {store_path}", file=sys.stderr)
    print(
        "   Saat Anda menjalankan 'nh os switch', proses akan selesai instan (0 ms)!",
        file=sys.stderr,
    )
    print(
        "================================================================================",
        file=sys.stderr,
    )


def download_batch_targets(
    all_pins: bool,
    cache_client: NixCacheClient,
    pins_file_path: Optional[str] = None,
    cache_dir: Optional[str] = None,
    split: int = 8,
    concurrent: int = 4,
    keep_nar: bool = False,
    verbose: bool = False,
    dry_run: bool = False,
):
    """Batch prefetch and ingest missing closures for active pins (or all pins)."""
    pins_file = find_cache_pins_file(pins_file_path)
    if not pins_file:
        print(
            "❌ ERROR: Tidak dapat menemukan berkas modules/_lib/cache-pins.nix",
            file=sys.stderr,
        )
        sys.exit(1)

    pins_data = load_cache_pins(pins_file)
    if not pins_data:
        print("❌ ERROR: Tidak ada entri pin yang ditemukan.", file=sys.stderr)
        sys.exit(1)

    if all_pins:
        target_keys = list(pins_data.keys())
        scope_title = "Seluruh Pin Terdaftar"
    else:
        used, _ = find_unused_pins(pins_file)
        target_keys = list(used.keys())
        scope_title = "Pin Aktif (Digunakan di Modul)"

    print(
        "================================================================================",
        file=sys.stderr,
    )
    print(
        f"📦 Pre-fetch Massal Cache Pins ({scope_title}: {len(target_keys)} paket)",
        file=sys.stderr,
    )
    print(f"🌐 Binary Cache         : {cache_client.summary_display}", file=sys.stderr)
    print(
        "================================================================================",
        file=sys.stderr,
    )

    missing_targets = []
    already_local = 0

    for k in sorted(target_keys):
        info = pins_data.get(k, {})
        sp = info.get("storePath", "")
        if not sp:
            continue
        if is_path_in_nix_store(sp):
            already_local += 1
        else:
            missing_targets.append((k, sp))

    print(
        f"  • Sudah Tersimpan di /nix/store : {already_local} paket (0 B overhead)",
        file=sys.stderr,
    )
    print(
        f"  • Perlu Diunduh dari Cache      : {len(missing_targets)} paket",
        file=sys.stderr,
    )

    if not missing_targets:
        print(
            "\n✨ Sempurna! Seluruh biner dan pustaka target sudah ada 100% di /nix/store lokal.",
            file=sys.stderr,
        )
        print(
            "   Rebuild sistem ('nh os switch') akan berjalan instan (0 ms download delay).",
            file=sys.stderr,
        )
        sys.exit(0)

    if dry_run:
        print("\n[DRY RUN] Paket yang perlu diunduh:", file=sys.stderr)
        for name, sp in missing_targets:
            print(f"   - [{name}] {sp}", file=sys.stderr)
        print(
            "\n(Mode dry-run: Tidak ada biner yang diunduh atau di-ingest)",
            file=sys.stderr,
        )
        sys.exit(0)

    ensure_aria2_installed()
    local_cache_dir = Path(cache_dir or get_default_ram_cache_dir()).resolve()
    local_cache_dir, nar_dir = setup_ram_cache_dir(local_cache_dir)

    print(
        "\n🔍 Memeriksa dan menggabungkan seluruh closure dependencies...",
        file=sys.stderr,
    )
    auditor = ClosureAuditor(cache_client)
    all_narinfos = {}
    all_download_items_map = {}

    for name, sp in missing_targets:
        sname = os.path.basename(sp)
        narinfos, items = auditor.traverse_closure_for_download(sname)
        all_narinfos.update(narinfos)
        for item in items:
            all_download_items_map[item.hash] = item

    all_download_items = list(all_download_items_map.values())
    total_bytes = sum(i.file_size for i in all_download_items)

    print(
        f"📋 Total {len(all_download_items)} file arsip NAR yang perlu diunduh ({format_bytes(total_bytes)}).",
        file=sys.stderr,
    )

    for h, info in all_narinfos.items():
        (local_cache_dir / f"{h}.narinfo").write_text(info.raw_text)

    if all_download_items:
        print(
            f"\n🚀 Streaming download & instant ingestion ({len(all_download_items)} paket) ke RAM tmpfs ({local_cache_dir}) via aria2c + nix copy ({split} koneksi)...",
            file=sys.stderr,
        )
        pipeline = StreamingIngestPipeline(
            cache_client=cache_client,
            local_cache_dir=local_cache_dir,
            concurrent=concurrent,
            split=split,
            keep_nar=keep_nar,
            verbose=verbose,
        )
        ok = pipeline.run(download_items=all_download_items, narinfos=all_narinfos)
        if not ok:
            print("❌ ERROR: Unduhan batch streaming via aria2c gagal.", file=sys.stderr)
            sys.exit(1)

    if not keep_nar:
        cleanup_ram_cache(nar_dir)
        print(
            "🧹 RAM Cache (.nar archives) otomatis dibersihkan (Zero SSD Wear).",
            file=sys.stderr,
        )

    print(
        "================================================================================",
        file=sys.stderr,
    )
    print("🎉 SUKSES! Seluruh paket target telah siap di /nix/store.", file=sys.stderr)
    print(
        "================================================================================",
        file=sys.stderr,
    )
    sys.exit(0)


def download_system_targets(
    cache_client: NixCacheClient,
    hostname: Optional[str] = None,
    cache_dir: Optional[str] = None,
    split: int = 8,
    concurrent: int = 4,
    keep_nar: bool = False,
    verbose: bool = False,
    dry_run: bool = False,
):
    """Prefetch and ingest all missing system closure store paths (Substituter + FOD) using aria2c."""
    ensure_aria2_installed()
    flake_dir = find_flake_dir()
    if not flake_dir:
        print(
            "❌ ERROR: Direktori flake (berisi flake.nix) tidak ditemukan.",
            file=sys.stderr,
        )
        sys.exit(1)

    host = hostname or get_system_hostname(flake_dir)
    print(
        "================================================================================",
        file=sys.stderr,
    )
    print(
        f"🖥️  Target Sistem NixOS : {host} (config.system.build.toplevel)",
        file=sys.stderr,
    )
    print(f"🌐 Binary Caches        : {cache_client.summary_display}", file=sys.stderr)
    print(
        "================================================================================",
        file=sys.stderr,
    )

    print(
        "🔍 [1/3] Mengevaluasi closure sistem & memeriksa biner yang belum ada di lokal...",
        file=sys.stderr,
    )
    try:
        missing_paths, missing_fods, meta = evaluate_system_missing_paths(
            flake_dir=flake_dir,
            hostname=host,
            verbose=verbose,
        )
    except Exception as e:
        print(f"❌ ERROR saat evaluasi sistem: {e}", file=sys.stderr)
        sys.exit(1)

    total_missing = len(missing_paths) + len(missing_fods)
    if total_missing == 0:
        print(
            "\n✨ SEMPURNA! Seluruh biner sistem sudah 100% ada dan valid di /nix/store lokal.",
            file=sys.stderr,
        )
        print(
            "   Tidak ada paket yang perlu diunduh dari internet (0 Byte overhead).",
            file=sys.stderr,
        )
        print(
            "   Rebuild sistem ('nh os switch') akan berjalan instan!", file=sys.stderr
        )
        print(
            "================================================================================",
            file=sys.stderr,
        )
        return

    dl_size_str = meta.get("download_size", "0 B")
    unpack_size_str = meta.get("unpacked_size", "0 B")
    print(
        f"📋 Ditemukan {total_missing} item yang belum ada di /nix/store lokal:",
        file=sys.stderr,
    )
    if missing_paths:
        print(f"   • Substituter Caches : {len(missing_paths)} paket NAR ({dl_size_str})", file=sys.stderr)
    if missing_fods:
        print(f"   • Fixed-Output (FOD) : {len(missing_fods)} berkas hulu (fetchurl / source tarball)", file=sys.stderr)

    if dry_run:
        if missing_paths:
            print("\n[DRY RUN] Biner Substituter yang perlu diunduh:", file=sys.stderr)
            for p in missing_paths:
                print(f"   - [substituter] {p}", file=sys.stderr)
        if missing_fods:
            print("\n[DRY RUN] Berkas Sumber Hulu (FOD) yang perlu diunduh:", file=sys.stderr)
            for f in missing_fods:
                print(f"   - [FOD] {f.filename} ({f.url}) ➔ {f.out_path}", file=sys.stderr)
        print(
            "\n(Mode dry-run: Tidak ada biner yang diunduh atau di-ingest)",
            file=sys.stderr,
        )
        return

    import subprocess

    for sp in missing_paths:
        if os.path.exists(sp) and not is_path_in_nix_store(sp):
            print(
                f"🧹 Membersihkan sisa biner parsial/tidak valid: {os.path.basename(sp)}",
                file=sys.stderr,
            )
            subprocess.run(
                ["nix-store", "--delete", sp],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )

    for f in missing_fods:
        if os.path.exists(f.out_path) and not is_path_in_nix_store(f.out_path):
            print(
                f"🧹 Membersihkan sisa biner FOD tidak valid: {f.filename}",
                file=sys.stderr,
            )
            subprocess.run(
                ["nix-store", "--delete", f.out_path],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )

    local_cache_dir = Path(cache_dir or get_default_ram_cache_dir()).resolve()
    local_cache_dir, nar_dir = setup_ram_cache_dir(local_cache_dir)

    all_download_items: List[DownloadItem] = []

    if missing_paths:
        print(
            f"\n🌐 Mengambil metadata narinfo dari binary cache untuk {len(missing_paths)} biner...",
            file=sys.stderr,
        )
        hash_to_sp = {}
        for sp in missing_paths:
            h = os.path.basename(sp).split("-")[0]
            hash_to_sp[h] = sp

        all_narinfos = {}
        all_download_items_map = {}

        max_workers = min(32, max(8, len(hash_to_sp)))
        with ThreadPoolExecutor(max_workers=max_workers) as executor:
            future_to_hash = {
                executor.submit(cache_client.fetch_narinfo, h): (h, sp)
                for h, sp in hash_to_sp.items()
            }
            done_count = 0
            total_count = len(future_to_hash)
            for future in as_completed(future_to_hash):
                h, sp = future_to_hash[future]
                done_count += 1
                if done_count % 25 == 0 or done_count == total_count:
                    pct = int(done_count / total_count * 100)
                    sys.stderr.write(
                        f"\r   ⏳ Mengambil metadata narinfo: [{done_count}/{total_count}] ({pct}%)"
                    )
                    sys.stderr.flush()

                info = future.result()
                if info:
                    all_narinfos[h] = info
                    (local_cache_dir / f"{h}.narinfo").write_text(info.raw_text)
                    if info.url:
                        dl_url = (
                            f"{info.source_cache_url}/{info.url}"
                            if not info.url.startswith("http")
                            else info.url
                        )
                        fn = os.path.basename(info.url)
                        if fn not in all_download_items_map:
                            all_download_items_map[fn] = DownloadItem(
                                hash=h,
                                url=dl_url,
                                filename=fn,
                                file_size=info.file_size,
                                source_cache_url=info.source_cache_url,
                            )

        # Quick pass: check if any references are not in all_narinfos and not yet in /nix/store
        extra_hashes = set()
        for info in list(all_narinfos.values()):
            for ref in info.references:
                ref_h = ref.split("-")[0]
                if ref_h not in all_narinfos:
                    ref_sp = f"/nix/store/{ref}" if not ref.startswith("/nix/store/") else ref
                    if not is_path_in_nix_store(ref_sp):
                        extra_hashes.add(ref_h)

        if extra_hashes:
            with ThreadPoolExecutor(max_workers=min(16, len(extra_hashes))) as executor:
                extra_futures = {executor.submit(cache_client.fetch_narinfo, h): h for h in extra_hashes}
                for f in as_completed(extra_futures):
                    h = extra_futures[f]
                    info = f.result()
                    if info:
                        all_narinfos[h] = info
                        (local_cache_dir / f"{h}.narinfo").write_text(info.raw_text)
                        if info.url:
                            fn = os.path.basename(info.url)
                            if fn not in all_download_items_map:
                                dl_url = (
                                    f"{info.source_cache_url}/{info.url}"
                                    if not info.url.startswith("http")
                                    else info.url
                                )
                                all_download_items_map[fn] = DownloadItem(
                                    hash=h,
                                    url=dl_url,
                                    filename=fn,
                                    file_size=info.file_size,
                                    source_cache_url=info.source_cache_url,
                                )

        sys.stderr.write(
            f"\r\033[K   ✔ Metadata narinfo berhasil diperoleh ({len(all_narinfos)} paket)\n"
        )
        sys.stderr.flush()

        all_download_items.extend(list(all_download_items_map.values()))

    if missing_fods:
        seen_fod_paths = set()
        for f in missing_fods:
            if f.out_path in seen_fod_paths:
                continue
            seen_fod_paths.add(f.out_path)
            fn = getattr(f, "download_filename", None) or f.filename
            all_download_items.append(
                DownloadItem(
                    hash=f.out_path,
                    url=f.url,
                    filename=fn,
                    file_size=f.file_size,
                    source_cache_url="upstream",
                )
            )

    total_bytes = sum(i.file_size for i in all_download_items)
    print(
        f"📋 Total {len(all_download_items)} file yang akan diunduh ({format_bytes(total_bytes) if total_bytes > 0 else 'ukuran dinamis'}).",
        file=sys.stderr,
    )

    if all_download_items:
        print(
            f"\n🚀 [2/3] Streaming download & instant ingestion ({len(all_download_items)} item) ke RAM via aria2c + nix copy ({split} koneksi)...",
            file=sys.stderr,
        )
        pipeline = StreamingIngestPipeline(
            cache_client=cache_client,
            local_cache_dir=local_cache_dir,
            concurrent=concurrent,
            split=split,
            keep_nar=keep_nar,
            verbose=verbose,
        )
        ok = pipeline.run(
            download_items=all_download_items,
            narinfos=all_narinfos if missing_paths else {},
            fod_items=missing_fods if missing_fods else None,
        )
        if not ok:
            print(
                "❌ ERROR: Unduhan atau ingest streaming sistem via aria2c gagal.",
                file=sys.stderr,
            )
            sys.exit(1)

    if not keep_nar:
        cleanup_ram_cache(nar_dir)
        print(
            "🧹 RAM Cache (.nar & FOD archives) otomatis dibersihkan (Zero SSD Wear).",
            file=sys.stderr,
        )

    print(
        "================================================================================",
        file=sys.stderr,
    )
    print(
        "🎉 SUKSES! Seluruh biner sistem & FOD telah ter-ingest ke /nix/store lokal.",
        file=sys.stderr,
    )
    print("   Sekarang Anda dapat menjalankan:", file=sys.stderr)
    print("   👉 nh os switch", file=sys.stderr)
    print(
        "   Proses switch sistem akan berjalan instan (0 Byte unduhan melalui Nix)!",
        file=sys.stderr,
    )
    print(
        "================================================================================",
        file=sys.stderr,
    )


def download_fod_target(
    drv_path: str,
    cache_dir: Optional[str] = None,
    split: int = 8,
    concurrent: int = 4,
    keep_nar: bool = False,
    verbose: bool = False,
    dry_run: bool = False,
):
    """Download a standalone Fixed-Output Derivation (.drv) using aria2c and ingest via nix-store --add-fixed."""
    ensure_aria2_installed()
    fods = extract_missing_fods([drv_path])
    if not fods:
        print(f"ℹ️ Derivasi '{os.path.basename(drv_path)}' bukan FOD atau sudah ada di /nix/store.", file=sys.stderr)
        return

    fod = fods[0]
    print("================================================================================", file=sys.stderr)
    print(f"📦 Unduhan FOD Mandiri : {fod.filename}", file=sys.stderr)
    print(f"🌐 URL Sumber           : {fod.url}", file=sys.stderr)
    print(f"🎯 Target Store Path    : {fod.out_path}", file=sys.stderr)
    print(f"🔒 Hash Mode & Algo     : {fod.hash_algo} ({fod.hash_mode})", file=sys.stderr)
    print("================================================================================", file=sys.stderr)

    if dry_run:
        print("\n[DRY RUN] Berkas siap diunduh via aria2c (mode dry-run).", file=sys.stderr)
        return

    import subprocess
    if os.path.exists(fod.out_path) and not is_path_in_nix_store(fod.out_path):
        print(f"🧹 Membersihkan residu invalid: {fod.filename}", file=sys.stderr)
        subprocess.run(["nix-store", "--delete", fod.out_path], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    local_cache_dir = Path(cache_dir or get_default_ram_cache_dir()).resolve()
    local_cache_dir, nar_dir = setup_ram_cache_dir(local_cache_dir)

    fn = getattr(fod, "download_filename", None) or fod.filename
    dl_item = DownloadItem(
        hash=fod.out_path,
        url=fod.url,
        filename=fn,
        file_size=fod.file_size,
        source_cache_url="upstream",
    )
    print(f"\n🚀 Streaming download & instant ingestion FOD ke RAM via aria2c + nix-store --add-fixed ({split} koneksi)...", file=sys.stderr)
    pipeline = StreamingIngestPipeline(
        cache_client=NixCacheClient(),
        local_cache_dir=local_cache_dir,
        concurrent=concurrent,
        split=split,
        keep_nar=keep_nar,
        verbose=verbose,
    )
    ok = pipeline.run(
        download_items=[dl_item],
        narinfos={},
        fod_items=[fod],
    )
    if not ok:
        print("❌ ERROR: Unduhan atau ingest FOD gagal.", file=sys.stderr)
        sys.exit(1)

    if not keep_nar:
        cleanup_ram_cache(nar_dir)

    print("================================================================================", file=sys.stderr)
    print(f"🎉 SUKSES! Berkas FOD telah sah terdaftar di {fod.out_path}.", file=sys.stderr)
    print("================================================================================", file=sys.stderr)
