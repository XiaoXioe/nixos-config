#!/usr/bin/env python3
"""aria2-fetch-pin — CLI for multi-connection parallel NAR closure downloads to RAM tmpfs."""
import argparse
import os
from pathlib import Path
import sys

_scripts_dir = str(Path(__file__).resolve().parent)
if _scripts_dir not in sys.path:
    sys.path.insert(0, _scripts_dir)

from core.cache_client import NixCacheClient
from core.nix_eval import resolve_channel_input
from downloader.orchestrator import download_batch_targets, download_single_target
from downloader.ram_cache import get_default_ram_cache_dir
from ui.tui import launch_cache_dashboard
from ui.version_picker import interactive_version_picker


def main():
    """Main CLI entrypoint for aria2-fetch-pin (afp)."""
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
        "--all-active",
        action="store_true",
        help="Unduh secara massal seluruh pin yang aktif di modul ke /nix/store",
    )
    parser.add_argument(
        "--all-pins",
        action="store_true",
        help="Unduh secara massal seluruh pin di cache-pins.nix ke /nix/store",
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
        default=None,
        help="Binary cache URL (dukungan multi-cache dipisahkan koma, default: auto-detect substituters sistem)",
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

    cache_client = NixCacheClient(cache_url=args.cache_url)

    if args.all_active or args.all_pins:
        download_batch_targets(
            all_pins=args.all_pins,
            cache_client=cache_client,
            pins_file_path=args.pins_file,
            cache_dir=args.cache_dir,
            split=args.split,
            concurrent=args.concurrent,
            keep_nar=args.keep_nar,
        )
        sys.exit(0)

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
        selected_version = interactive_version_picker(target_input, cache_url=args.cache_url)
        if not selected_version:
            print("Pencarian versi dibatalkan.", file=sys.stderr)
            sys.exit(0)
        args.input = selected_version["flake_input"]
        target_input = selected_version["attr"]
        print(f"🎯 Versi terpilih: v{selected_version['version']} ({args.input})", file=sys.stderr)

    download_single_target(
        target_input=target_input,
        cache_client=cache_client,
        nixpkgs_input=args.input if args.input else "nixpkgs",
        pins_file_path=args.pins_file,
        cache_dir=args.cache_dir,
        split=args.split,
        concurrent=args.concurrent,
        keep_nar=args.keep_nar,
    )


if __name__ == "__main__":
    main()
