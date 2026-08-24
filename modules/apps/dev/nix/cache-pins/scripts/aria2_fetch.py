#!/usr/bin/env python3
"""aria2-fetch-pin — Unduh paket & seluruh library closure-nya ke RAM (tmpfs) menggunakan aria2c dengan auto-resume & auto-cleanup."""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import sys

_scripts_dir = str(Path(__file__).resolve().parent)
if _scripts_dir not in sys.path:
    sys.path.insert(0, _scripts_dir)

from cache_client import NixCacheClient
from formatters import format_bytes
from nix_utils import (
    find_cache_pins_file,
    is_path_in_nix_store,
    resolve_channel_input,
    resolve_target_to_store_path,
)
from tui import launch_cache_dashboard
from version_search import interactive_version_picker


def get_default_ram_cache_dir() -> str:
    """Get the preferred RAM tmpfs directory path."""
    env_dir = os.environ.get("LOCAL_CACHE_DIR")
    if env_dir:
        return env_dir

    runtime_dir = os.environ.get("XDG_RUNTIME_DIR")
    if runtime_dir and os.path.isdir(runtime_dir):
        return str(Path(runtime_dir) / "nix-aria2")

    if os.path.isdir("/dev/shm"):
        return f"/dev/shm/nix-aria2-{os.getuid()}"

    return f"/tmp/nix-aria2-{os.getuid()}"


def main():
    parser = argparse.ArgumentParser(
        description="aria2-fetch-pin — Unduh paket & closure ke RAM (tmpfs) menggunakan aria2c dengan auto-resume"
    )
    parser.add_argument(
        "target",
        nargs="?",
        help="Nama paket di cache-pins.nix, store-path (/nix/store/...), atau pkgs.<attr>",
    )
    parser.add_argument(
        "-c",
        "--channel",
        help="Shorthand channel Nixpkgs (contoh: unstable, 26.05, 25.11, 25.05, 24.11, master)",
    )
    parser.add_argument(
        "-i",
        "--interactive",
        action="store_true",
        help="Buka TUI Dashboard interaktif berbasis fzf untuk memilih dan mengunduh paket",
    )
    parser.add_argument(
        "-s",
        "--search-versions",
        action="store_true",
        help="Cari versi lain dari paket via FZF sebelum mengunduh",
    )
    parser.add_argument(
        "--keep-nar",
        action="store_true",
        help="Pertahankan file arsip .nar di RAM setelah ingest selesai (default: dibersihkan)",
    )
    parser.add_argument(
        "--cache-url",
        default=os.environ.get("CACHE_URL", "https://cache.nixos.org"),
        help="Binary cache URL (dukungan multi-cache dipisahkan koma)",
    )
    parser.add_argument(
        "--input",
        default=os.environ.get("NIXPKGS_INPUT", ""),
        help="Flake input target (contoh: github:NixOS/nixpkgs/nixos-unstable)",
    )
    parser.add_argument(
        "--cache-dir",
        default=get_default_ram_cache_dir(),
        help="Direktori cache lokal aria2 di RAM (default: $XDG_RUNTIME_DIR/nix-aria2)",
    )
    parser.add_argument(
        "--split",
        type=int,
        default=8,
        help="Koneksi paralel per file (split, default: 8)",
    )
    parser.add_argument(
        "--concurrent",
        "-j",
        type=int,
        default=4,
        help="Maksimum download bersamaan (max-concurrent-downloads, default: 4)",
    )
    parser.add_argument("--pins-file", help="Path eksplisit ke berkas cache-pins.nix")

    args = parser.parse_args()

    # Handle channel shorthand
    if args.channel:
        args.input = resolve_channel_input(args.channel)

    if args.interactive or (not args.target and not args.search_versions):
        launch_cache_dashboard(
            pins_file_path=args.pins_file,
            cache_url=args.cache_url,
            nixpkgs_input=args.input if args.input else "nixpkgs",
        )
        sys.exit(0)

    target_input = args.target

    if args.search_versions:
        if not target_input:
            target_input = input("Masukkan nama paket yang ingin dicari versinya: ").strip()
            if not target_input:
                sys.exit(0)
        selected_version = interactive_version_picker(target_input)
        if not selected_version:
            print("Pencarian versi dibatalkan.", file=sys.stderr)
            sys.exit(0)
        args.input = selected_version["flake_input"]
        target_input = selected_version["attr"]
        print(f"🎯 Versi terpilih: v{selected_version['version']} ({args.input})", file=sys.stderr)

    # Pastikan aria2c terpasang
    which_aria2 = subprocess.run(["which", "aria2c"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    if which_aria2.returncode != 0:
        which_aria2 = subprocess.run(
            ["command", "-v", "aria2c"], shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
        )
        if which_aria2.returncode != 0:
            print("❌ ERROR: 'aria2c' tidak ditemukan di sistem Anda.", file=sys.stderr)
            print(
                "   Silakan instal aria2 atau jalankan via 'nix shell nixpkgs#aria2 --command ...'",
                file=sys.stderr,
            )
            sys.exit(1)

    local_cache_dir = Path(args.cache_dir).resolve()
    pins_file = find_cache_pins_file(args.pins_file)

    # 1. Resolusi Target ke Store Path
    try:
        store_path, _, _ = resolve_target_to_store_path(
            target=target_input,
            nixpkgs_input=args.input if args.input else "nixpkgs",
            pins_file=pins_file,
        )
    except Exception as e:
        print(f"❌ ERROR: {e}", file=sys.stderr)
        sys.exit(1)

    store_name = os.path.basename(store_path)

    print("================================================================================", file=sys.stderr)
    print(f"📦 Target Package       : {store_name}", file=sys.stderr)
    print(f"🔗 Store Path           : {store_path}", file=sys.stderr)
    print(f"💾 Penyimpanan Unduhan  : RAM (tmpfs: {local_cache_dir}) [Zero SSD Wear]", file=sys.stderr)
    print("================================================================================", file=sys.stderr)

    # 2. Cek Apakah Path Sudah Ada & Valid di /nix/store
    if is_path_in_nix_store(store_path):
        print("✅ Path sudah ada dan terdaftar secara valid di /nix/store!", file=sys.stderr)
        print("   Tidak memerlukan unduhan internet (0 Byte overhead).", file=sys.stderr)
        sys.exit(0)

    # 3. Inisialisasi Struktur Local File Binary Cache di RAM
    nar_dir = local_cache_dir / "nar"
    nar_dir.mkdir(parents=True, exist_ok=True)
    cache_info_file = local_cache_dir / "nix-cache-info"
    if not cache_info_file.exists():
        cache_info_file.write_text("StoreDir: /nix/store\nWantMassQuery: 0\nPriority: 0\n")

    # 4. Ambil Metadata .narinfo & Scan Seluruh Missing Dependencies
    cache_client = NixCacheClient(cache_url=args.cache_url)
    print(f"🌐 [1/3] Memeriksa pohon dependensi closure dari {cache_client.cache_url}...", file=sys.stderr)
    narinfos, items_to_download = cache_client.traverse_closure_for_download(store_name)

    # Simpan semua .narinfo ke local cache
    for h, info in narinfos.items():
        narinfo_file = local_cache_dir / f"{h}.narinfo"
        narinfo_file.write_text(info.raw_text)

    total_items = len(items_to_download)
    total_size_bytes = sum(item.file_size for item in items_to_download)
    print(
        f"📋 Ditemukan {total_items} paket closure yang perlu diunduh (Total: {format_bytes(total_size_bytes)})",
        file=sys.stderr,
    )

    # 5. Generate Aria2 Batch Download File
    aria2_input_file = local_cache_dir / "aria2_batch.txt"
    with open(aria2_input_file, "w") as f:
        for item in items_to_download:
            f.write(f"{item.url}\n")
            f.write(f"  dir={nar_dir}\n")
            f.write(f"  out={item.filename}\n")

    # 6. Jalankan aria2c Batch Multi-Connection Download ke RAM
    if total_items > 0:
        print("", file=sys.stderr)
        print(
            f"🚀 [2/3] Mengunduh {total_items} paket langsung ke RAM via aria2c ({args.split} koneksi paralel per file):",
            file=sys.stderr,
        )
        print("--------------------------------------------------------------------------------", file=sys.stderr)

        aria2_cmd = [
            "aria2c",
            f"--input-file={aria2_input_file}",
            "--continue=true",
            f"--max-concurrent-downloads={args.concurrent}",
            f"--max-connection-per-server={args.split}",
            f"--split={args.split}",
            "--min-split-size=1M",
            "--max-tries=0",
            "--retry-wait=2",
            "--connect-timeout=30",
            "--timeout=60",
            "--auto-file-renaming=false",
            "--allow-overwrite=true",
            f"--dir={nar_dir}",
        ]

        res = subprocess.run(aria2_cmd)
        if res.returncode != 0:
            print("❌ ERROR: Unduhan aria2c gagal atau dibatalkan.", file=sys.stderr)
            sys.exit(res.returncode)

        print("", file=sys.stderr)
        print("✅ Seluruh unduhan paket & library selesai 100% di RAM!", file=sys.stderr)

    # 7. Ingest Seluruh Path ke /nix/store Lokal via Nix Store Realise
    print("📥 [3/3] Meng-ingest biner + seluruh library dari cache RAM ke /nix/store...", file=sys.stderr)
    substituters_str = f"file://{local_cache_dir}?priority=0 " + " ".join(
        [f"{u}?priority=100" for u in cache_client.cache_urls]
    )
    nix_store_cmd = [
        "nix-store",
        "--realise",
        store_path,
        "--option",
        "substituters",
        substituters_str,
        "--option",
        "trusted-substituters",
        f"file://{local_cache_dir}",
        "--option",
        "fallback",
        "false",
    ]

    res = subprocess.run(nix_store_cmd, stdout=subprocess.DEVNULL)
    if res.returncode != 0:
        print(f"❌ ERROR: Gagal meng-ingest path {store_path} ke /nix/store", file=sys.stderr)
        sys.exit(res.returncode)

    # 8. Auto-cleanup RAM cache
    if not args.keep_nar and nar_dir.exists():
        shutil.rmtree(nar_dir, ignore_errors=True)
        nar_dir.mkdir(parents=True, exist_ok=True)
        print("🧹 RAM Cache (.nar archives) otomatis dibersihkan (0 Byte sisa di RAM).", file=sys.stderr)

    print("================================================================================", file=sys.stderr)
    print("🎉 SUKSES! Biner & seluruh library berhasil di-ingest ke /nix/store:", file=sys.stderr)
    print(f"   {store_path}", file=sys.stderr)
    print("   Saat Anda menjalankan 'nh os switch', proses akan selesai instan (0 ms)!", file=sys.stderr)
    print("================================================================================", file=sys.stderr)


if __name__ == "__main__":
    main()
