"""Orchestration workflows for single-target and multi-target batch pre-fetching."""

import os
import sys
from pathlib import Path
from typing import Optional

from core.cache_client import NixCacheClient
from core.closure import ClosureAuditor
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
from downloader.ingest import ingest_store_paths
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

    for h, info in narinfos.items():
        (local_cache_dir / f"{h}.narinfo").write_text(info.raw_text)

    total_items = len(items_to_download)
    total_size_bytes = sum(item.file_size for item in items_to_download)
    print(
        f"📋 Ditemukan {total_items} paket closure yang perlu diunduh (Total: {format_bytes(total_size_bytes)})",
        file=sys.stderr,
    )

    # 5. Generate Aria2 Batch
    aria2_input_file = local_cache_dir / "aria2_batch.txt"
    generate_aria2_batch_file(items_to_download, aria2_input_file, nar_dir)

    # 6. Download ke RAM
    if total_items > 0:
        print("", file=sys.stderr)
        print(
            f"🚀 [2/3] Mengunduh {total_items} paket langsung ke RAM via aria2c ({split} koneksi per file):",
            file=sys.stderr,
        )
        print(
            "--------------------------------------------------------------------------------",
            file=sys.stderr,
        )
        rc = run_aria2_download(
            aria2_input_file, nar_dir, concurrent=concurrent, split=split
        )
        if rc != 0:
            print("❌ ERROR: Unduhan aria2c gagal atau dibatalkan.", file=sys.stderr)
            sys.exit(rc)
        print(
            "\n✅ Seluruh unduhan paket & library selesai 100% di RAM!", file=sys.stderr
        )

    # 7. Ingest ke /nix/store
    print(
        "📥 [3/3] Meng-ingest biner + seluruh library dari cache RAM ke /nix/store...",
        file=sys.stderr,
    )
    ok = ingest_store_paths(store_path, local_cache_dir, cache_client.cache_urls)
    if not ok:
        print(
            f"❌ ERROR: Gagal meng-ingest path {store_path} ke /nix/store",
            file=sys.stderr,
        )
        sys.exit(1)

    # 8. Cleanup
    if not keep_nar:
        cleanup_ram_cache(nar_dir)
        print(
            "🧹 RAM Cache (.nar archives) otomatis dibersihkan (0 Byte sisa di RAM).",
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
        aria2_input_file = local_cache_dir / "aria2_batch.txt"
        generate_aria2_batch_file(all_download_items, aria2_input_file, nar_dir)

        print(
            f"\n🚀 Mengunduh ke RAM tmpfs ({local_cache_dir}) via aria2c ({split} koneksi per file)...",
            file=sys.stderr,
        )
        rc = run_aria2_download(
            aria2_input_file, nar_dir, concurrent=concurrent, split=split
        )
        if rc != 0:
            print("❌ ERROR: Unduhan batch aria2c gagal.", file=sys.stderr)
            sys.exit(rc)

    print(
        "\n📥 Meng-ingest seluruh biner dari cache RAM ke /nix/store...",
        file=sys.stderr,
    )
    missing_store_paths = [sp for _, sp in missing_targets]
    ingest_store_paths(missing_store_paths, local_cache_dir, cache_client.cache_urls)

    if not keep_nar:
        cleanup_ram_cache(nar_dir)

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
    """Prefetch and ingest all missing system closure store paths using aria2c."""
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
        missing_paths, meta = evaluate_system_missing_paths(
            flake_dir=flake_dir,
            hostname=host,
            verbose=verbose,
        )
    except Exception as e:
        print(f"❌ ERROR saat evaluasi sistem: {e}", file=sys.stderr)
        sys.exit(1)

    total_missing = len(missing_paths)
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

    dl_size_str = meta.get("download_size", "Unknown")
    unpack_size_str = meta.get("unpacked_size", "Unknown")
    print(
        f"📋 Ditemukan {total_missing} biner sistem yang belum ada di lokal:",
        file=sys.stderr,
    )
    print(f"   • Estimasi Ukuran Download : {dl_size_str}", file=sys.stderr)
    print(f"   • Estimasi Ukuran Ekstraksi: {unpack_size_str}", file=sys.stderr)

    if dry_run:
        print("\n[DRY RUN] Daftar biner yang perlu diunduh:", file=sys.stderr)
        for p in missing_paths:
            print(f"   - {p}", file=sys.stderr)
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

    local_cache_dir = Path(cache_dir or get_default_ram_cache_dir()).resolve()
    local_cache_dir, nar_dir = setup_ram_cache_dir(local_cache_dir)

    print(
        f"\n🌐 Mengambil metadata narinfo dari binary cache untuk {total_missing} biner...",
        file=sys.stderr,
    )
    auditor = ClosureAuditor(cache_client)
    all_narinfos = {}
    all_download_items_map = {}

    for sp in missing_paths:
        sname = os.path.basename(sp)
        narinfos, items = auditor.traverse_closure_for_download(sname)
        all_narinfos.update(narinfos)
        for item in items:
            all_download_items_map[item.hash] = item

    all_download_items = list(all_download_items_map.values())
    total_bytes = sum(i.file_size for i in all_download_items)

    print(
        f"📋 Total {len(all_download_items)} arsip NAR yang perlu diunduh ({format_bytes(total_bytes)}).",
        file=sys.stderr,
    )

    for h, info in all_narinfos.items():
        (local_cache_dir / f"{h}.narinfo").write_text(info.raw_text)

    if all_download_items:
        aria2_input_file = local_cache_dir / "aria2_batch.txt"
        generate_aria2_batch_file(all_download_items, aria2_input_file, nar_dir)

        print(
            f"\n🚀 [2/3] Mengunduh biner sistem ke RAM via aria2c ({split} koneksi per file)...",
            file=sys.stderr,
        )
        rc = run_aria2_download(
            aria2_input_file, nar_dir, concurrent=concurrent, split=split
        )
        if rc != 0:
            print("❌ ERROR: Unduhan batch sistem via aria2c gagal.", file=sys.stderr)
            sys.exit(rc)
        print("\n✅ Unduhan seluruh biner sistem selesai 100% di RAM!", file=sys.stderr)

    print(
        "\n📥 [3/3] Meng-ingest seluruh biner sistem dari cache RAM ke /nix/store...",
        file=sys.stderr,
    )
    ok = ingest_store_paths(missing_paths, local_cache_dir, cache_client.cache_urls)
    if not ok:
        print(
            "❌ ERROR: Sebagian biner gagal di-ingest ke /nix/store.", file=sys.stderr
        )
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
    print(
        "🎉 SUKSES! Seluruh biner sistem telah ter-ingest ke /nix/store lokal.",
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
