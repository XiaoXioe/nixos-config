#!/usr/bin/env python3
"""ncp — High-Performance Nix Binary Cache Downloader & Reactive Ingest Engine (v4.0.0)."""
import argparse
import os
from pathlib import Path
import sys

_scripts_dir = str(Path(__file__).resolve().parent.parent)
if _scripts_dir not in sys.path:
    sys.path.insert(0, _scripts_dir)

# Global unfree and insecure evaluation support
os.environ["NIXPKGS_ALLOW_UNFREE"] = "1"
os.environ["NIXPKGS_ALLOW_INSECURE"] = "1"
os.environ["NIXPKGS_ALLOW_BROKEN"] = "1"

__version__ = "4.0.0"


def create_parser() -> argparse.ArgumentParser:
    """Build the unified CLI argument parser for Nix binary cache download & reactive ingestion."""
    common_parser = argparse.ArgumentParser(add_help=False)
    global_group = common_parser.add_argument_group("global options")
    global_group.add_argument(
        "-c",
        "--channel",
        default=argparse.SUPPRESS,
        help="Shorthand channel Nixpkgs (contoh: unstable, nixpkgs-unstable, 26.05, 25.11, master)",
    )
    global_group.add_argument(
        "--cache-url",
        default=argparse.SUPPRESS,
        help="Binary cache URL (dukungan multi-cache dipisahkan koma, default: auto-detect substituters)",
    )
    global_group.add_argument(
        "--input",
        default=argparse.SUPPRESS,
        help="Flake input target (default: nixpkgs)",
    )
    global_group.add_argument(
        "--refresh",
        "--no-cache",
        action="store_true",
        dest="refresh",
        default=False,
        help="Abaikan cache evaluasi lokal dan paksa evaluasi ulang dari channel",
    )
    global_group.add_argument(
        "-j",
        "--concurrency",
        type=int,
        default=16,
        dest="concurrency",
        help="Tingkat paralelisme koneksi HTTP probing / evaluasi (default: 16)",
    )
    global_group.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        default=False,
        help="Tampilkan log stream proses evaluasi dan rincian dependensi lengkap",
    )

    parser = argparse.ArgumentParser(
        prog="ncp",
        description="ncp — High-Performance CLI untuk unduhan multi-koneksi aria2c & reactive ingest Nix binary cache.",
        parents=[common_parser],
    )
    parser.add_argument(
        "--version", action="version", version=f"%(prog)s {__version__}"
    )

    sub = parser.add_subparsers(
        dest="subcommand",
        title="subcommands",
        description="Gunakan 'ncp <subcommand> --help' untuk detail lebih lanjut.",
    )

    # === ncp fetch ===
    p_fetch = sub.add_parser(
        "fetch",
        aliases=["f"],
        parents=[common_parser],
        help="Download NAR/FOD closure via aria2c ke RAM tmpfs dan reactive ingest ke /nix/store",
        description="Unduh closure sistem NixOS (atau paket spesifik) ke RAM (tmpfs) menggunakan aria2c multi-connection, lalu ingest secara reaktif ke /nix/store.",
    )
    p_fetch.add_argument(
        "target",
        nargs="?",
        help="Target unduhan: 'system' (default), pkgs.<attr>, store-path (/nix/store/...), atau FOD (.drv)",
    )
    p_fetch.add_argument(
        "--system",
        action="store_true",
        help="Unduh seluruh biner closure sistem NixOS saat ini",
    )
    p_fetch.add_argument(
        "--host",
        default=None,
        help="Hostname target konfigurasi NixOS (default: auto-detect)",
    )
    p_fetch.add_argument(
        "--dry-run",
        action="store_true",
        help="Hanya tampilkan biner yang perlu diunduh tanpa mendownload",
    )
    p_fetch.add_argument(
        "--keep-nar",
        action="store_true",
        help="Pertahankan file .nar di RAM setelah ingest",
    )
    p_fetch.add_argument(
        "--split", type=int, default=8, help="Koneksi paralel per file (default: 8)"
    )
    p_fetch.add_argument(
        "--concurrent",
        type=int,
        default=4,
        help="Maksimum download bersamaan (default: 4)",
    )
    p_fetch.add_argument(
        "--cache-dir",
        default=None,
        help="Direktori cache lokal aria2 (default: RAM tmpfs)",
    )

    # === ncp update ===
    p_update = sub.add_parser(
        "update",
        aliases=["u"],
        parents=[common_parser],
        help="Perbarui flake.lock (atau input spesifik) lalu unduh & ingest closure sistem via aria2c",
        description="Perbarui flake.lock menggunakan 'nix flake update' lalu unduh closure sistem baru secara paralel via aria2c + reactive ingest.",
    )
    p_update.add_argument(
        "target",
        nargs="?",
        help="Flake input spesifik yang akan di-update (contoh: nixpkgs-unstable, nixpkgs, atau 'system' untuk semua)",
    )
    p_update.add_argument(
        "--system",
        action="store_true",
        help="Perbarui flake.lock dan unduh biner sistem baru via aria2c",
    )
    p_update.add_argument(
        "-i",
        "--flake-input",
        dest="flake_input",
        default=None,
        help="Flake input spesifik yang akan di-update (contoh: nixpkgs-unstable, nixpkgs, nix-cachyos-kernel)",
    )
    p_update.add_argument(
        "--host",
        default=None,
        help="Hostname target konfigurasi NixOS (default: auto-detect)",
    )
    p_update.add_argument(
        "--split",
        type=int,
        default=8,
        help="Koneksi paralel per file untuk download biner sistem (default: 8)",
    )
    p_update.add_argument(
        "--concurrent",
        type=int,
        default=4,
        help="Maksimum download bersamaan (default: 4)",
    )
    p_update.add_argument(
        "--cache-dir",
        default=None,
        help="Direktori cache lokal aria2 (default: RAM tmpfs)",
    )
    p_update.add_argument(
        "--keep-nar",
        action="store_true",
        help="Pertahankan file .nar di RAM setelah ingest",
    )
    p_update.add_argument(
        "--dry-run",
        action="store_true",
        help="Hanya evaluasi pembaruan tanpa mengunduh",
    )

    # === ncp query ===
    p_query = sub.add_parser(
        "query",
        aliases=["q"],
        parents=[common_parser],
        help="Cek status binary cache, ukuran closure, dan analisis dependensi paket",
        description="Evaluasi paket target dari Nixpkgs dan audit pohon dependensi closure di binary cache.",
    )
    p_query.add_argument(
        "target",
        nargs="?",
        help="Nama paket (pkgs.<attr> atau <attr>) atau store path (/nix/store/...)",
    )

    # === ncp tree ===
    p_tree = sub.add_parser(
        "tree",
        aliases=["t"],
        parents=[common_parser],
        help="Visualisasi grafik dependensi closure paket via nix-tree",
        description="Evaluasi store path paket dan buka penjelajah dependensi TUI interaktif berbasis nix-tree.",
    )
    p_tree.add_argument("target", help="Nama paket atau store path (/nix/store/...)")

    # === ncp search ===
    p_search = sub.add_parser(
        "search",
        aliases=["s"],
        parents=[common_parser],
        help="Cari versi paket lintas channel via FZF (NixHub, Git tags, Flake inputs)",
    )
    p_search.add_argument(
        "target", nargs="?", help="Nama paket yang ingin dicari versinya"
    )

    return parser


def main(argv=None):
    """Main entry point for ncp binary cache ingest CLI."""
    parser = create_parser()
    args = parser.parse_args(argv)

    if not args.subcommand:
        parser.print_help(file=sys.stderr)
        sys.exit(1)

    if not hasattr(args, "input"):
        args.input = os.environ.get("NIXPKGS_INPUT", "nixpkgs")
    if not hasattr(args, "channel"):
        args.channel = None
    if not hasattr(args, "cache_url"):
        args.cache_url = None
    if not hasattr(args, "refresh"):
        args.refresh = False
    if not hasattr(args, "concurrency"):
        args.concurrency = 16

    if getattr(args, "verbose", False):
        os.environ["NCP_VERBOSE"] = "1"

    if hasattr(args, "channel") and args.channel:
        from core.eval.channels import resolve_channel_input

        args.input = resolve_channel_input(args.channel)

    cmd = args.subcommand
    if cmd in ("fetch", "f"):
        from cli.commands.fetch import handle_fetch

        handle_fetch(args)
    elif cmd in ("update", "u"):
        from cli.commands.update import handle_update

        handle_update(args)
    elif cmd in ("query", "q"):
        from cli.commands.query import handle_query

        handle_query(args)
    elif cmd in ("tree", "t"):
        from cli.commands.tree import handle_tree

        handle_tree(args)
    elif cmd in ("search", "s"):
        from cli.commands.search import handle_search

        handle_search(args)


if __name__ == "__main__":
    main()
