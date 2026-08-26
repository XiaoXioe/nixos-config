#!/usr/bin/env python3
"""nix-cache-pin (ncp) — Unified CLI for Nix binary cache pin management."""
import argparse
import os
from pathlib import Path
import sys

_scripts_dir = str(Path(__file__).resolve().parent.parent)
if _scripts_dir not in sys.path:
    sys.path.insert(0, _scripts_dir)

# Izinkan evaluasi paket berlisensi unfree dan insecure secara global
os.environ["NIXPKGS_ALLOW_UNFREE"] = "1"
os.environ["NIXPKGS_ALLOW_INSECURE"] = "1"

__version__ = "2.0.0"


def create_parser() -> argparse.ArgumentParser:
    """Build the unified CLI argument parser with subcommands."""
    common_parser = argparse.ArgumentParser(add_help=False)
    global_group = common_parser.add_argument_group("global options")
    global_group.add_argument(
        "-c", "--channel",
        default=argparse.SUPPRESS,
        help="Shorthand channel Nixpkgs (contoh: unstable, 26.05, 25.11, 25.05, 24.11, master)",
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
        "--pins-file",
        default=argparse.SUPPRESS,
        help="Path eksplisit ke berkas cache-pins.nix",
    )
    global_group.add_argument(
        "-v", "--verbose",
        action="store_true",
        default=False,
        help="Tampilkan log stream proses evaluasi dan rincian dependensi lengkap",
    )

    parser = argparse.ArgumentParser(
        prog="ncp",
        description="nix-cache-pin (ncp) — Unified CLI untuk manajemen pin Nix binary cache: query, fetch, update, audit, adopt, dan lainnya.",
        parents=[common_parser],
    )
    parser.add_argument("--version", action="version", version=f"%(prog)s {__version__}")

    sub = parser.add_subparsers(
        dest="subcommand", title="subcommands",
        description="Gunakan 'ncp <subcommand> --help' untuk detail lebih lanjut.",
    )

    # === ncp query ===
    p_query = sub.add_parser(
        "query", aliases=["q"],
        parents=[common_parser],
        help="Cek status cache, closure size, narinfo, dan generate Nix snippet",
        description="Evaluasi paket target, audit pohon dependensi closure, dan generate template cache-pins.nix.",
    )
    p_query.add_argument("target", nargs="?", help="Nama paket (pkgs.<attr> atau <attr>), store path (/nix/store/...), atau key cache-pins")
    p_query.add_argument("-w", "--write", action="store_true", help="Otomatis tulis/perbarui entri di cache-pins.nix")
    p_query.add_argument("--all", action="store_true", help="Verifikasi ketersediaan seluruh entri di cache-pins.nix")

    # === ncp fetch ===
    p_fetch = sub.add_parser(
        "fetch", aliases=["f"],
        parents=[common_parser],
        help="Download NAR closure via aria2c ke RAM tmpfs dan ingest ke /nix/store",
        description="Unduh paket dan seluruh closure ke RAM (tmpfs) menggunakan aria2c multi-connection, lalu ingest ke /nix/store.",
    )
    p_fetch.add_argument("target", nargs="?", help="Nama paket di cache-pins.nix, store-path, atau pkgs.<attr>")
    p_fetch.add_argument("--all-active", action="store_true", help="Unduh massal seluruh pin aktif di modul")
    p_fetch.add_argument("--all-pins", action="store_true", help="Unduh massal seluruh pin terdaftar")
    p_fetch.add_argument("--keep-nar", action="store_true", help="Pertahankan file .nar di RAM setelah ingest")
    p_fetch.add_argument("--split", type=int, default=8, help="Koneksi paralel per file (default: 8)")
    p_fetch.add_argument("-j", "--concurrent", type=int, default=4, help="Maksimum download bersamaan (default: 4)")
    p_fetch.add_argument("--cache-dir", default=None, help="Direktori cache lokal aria2 (default: RAM tmpfs)")

    # === ncp update ===
    p_update = sub.add_parser(
        "update", aliases=["u"],
        parents=[common_parser],
        help="Periksa dan perbarui pin dari upstream channel",
        description="Periksa pembaruan upstream untuk pin spesifik atau seluruh entri, dengan downgrade guard dan version-only filter.",
    )
    p_update.add_argument("target", nargs="?", help="Key paket spesifik yang akan di-update")
    p_update.add_argument("--all", action="store_true", help="Perbarui seluruh entri cache-pins.nix dari upstream")
    p_update.add_argument("-w", "--write", action="store_true", help="Simpan perubahan ke cache-pins.nix (default: dry-run)")
    p_update.add_argument("-f", "--force", action="store_true", help="Izinkan downgrade versi")
    p_update.add_argument(
        "--version-only", "--bump-only", action="store_true", dest="version_only",
        help="Hanya perbarui jika versi rilis naik (abaikan rebuild berversi sama)",
    )

    # === ncp audit ===
    p_audit = sub.add_parser(
        "audit", aliases=["a"],
        parents=[common_parser],
        help="Audit penggunaan pin di codebase (deteksi dangling/orphan pins)",
        description="Scan seluruh modul NixOS untuk mendeteksi pin aktif vs pin yatim yang tidak lagi terpakai.",
    )
    p_audit.add_argument("--clean", action="store_true", help="Hapus seluruh pin yatim dari cache-pins.nix")
    p_audit.add_argument("-f", "--force", action="store_true", help="Lewati konfirmasi interaktif saat membersihkan")

    # === ncp adopt ===
    p_adopt = sub.add_parser(
        "adopt",
        parents=[common_parser],
        help="Adopsi paket dari pkgs ke cache-pin dan refactor modul target",
        description="Evaluasi paket, tulis pin ke cache-pins.nix, dan refactor pkgs.<name> menjadi selfLib.fetchCachePinned.",
    )
    p_adopt.add_argument("target", help="Nama paket (pkgs.<attr> atau <attr>)")
    p_adopt.add_argument("module_path", nargs="?", help="Path file modul .nix target (opsional, auto-detect)")

    # === ncp tui ===
    sub.add_parser(
        "tui", aliases=["dashboard"],
        parents=[common_parser],
        help="Buka FZF Dashboard interaktif untuk menjelajahi dan mengunduh cache pins",
    )

    # === ncp stats ===
    sub.add_parser(
        "stats", aliases=["summary"],
        parents=[common_parser],
        help="Tampilkan dashboard statistik, kesehatan pin, dan kesiapan /nix/store",
    )

    # === ncp diff ===
    p_diff = sub.add_parser(
        "diff", aliases=["d"],
        parents=[common_parser],
        help="Bandingkan closure dependensi antara pin lokal vs versi upstream",
        description="Bandingkan library closure dan versi biner antara pin lokal di cache-pins.nix vs rilis upstream channel.",
    )
    p_diff.add_argument("target", help="Nama paket yang ingin dibandingkan")
    p_diff.add_argument("--deep", action="store_true", help="Gunakan nix-diff untuk analisis semantik AST derivation mendalam")

    # === ncp tree ===
    p_tree = sub.add_parser(
        "tree", aliases=["t"],
        parents=[common_parser],
        help="Visualisasi grafik dependensi closure paket via nix-tree",
        description="Evaluasi store path paket dan buka penjelajah dependensi TUI interaktif berbasis nix-tree.",
    )
    p_tree.add_argument("target", help="Nama paket atau store path (/nix/store/...)")

    # === ncp delete ===
    p_delete = sub.add_parser(
        "delete", aliases=["rm", "del"],
        parents=[common_parser],
        help="Hapus entri pin dari cache-pins.nix",
    )
    p_delete.add_argument("target", help="Key pin yang akan dihapus")

    # === ncp search ===
    p_search = sub.add_parser(
        "search", aliases=["s"],
        parents=[common_parser],
        help="Cari versi lain dari paket via FZF (NixHub, Git tags, Flake inputs)",
    )
    p_search.add_argument("target", nargs="?", help="Nama paket yang ingin dicari versinya")

    return parser


def main(argv=None):
    """Main entry point for nix-cache-pin unified CLI."""
    parser = create_parser()
    args = parser.parse_args(argv)

    if not args.subcommand:
        parser.print_help(file=sys.stderr)
        sys.exit(1)

    # Fill default values for global options if not set
    if not hasattr(args, "input"):
        args.input = os.environ.get("NIXPKGS_INPUT", "nixpkgs")
    if not hasattr(args, "channel"):
        args.channel = None
    if not hasattr(args, "cache_url"):
        args.cache_url = None
    if not hasattr(args, "pins_file"):
        args.pins_file = None

    # Set global verbose mode environment
    if getattr(args, "verbose", False):
        os.environ["NCP_VERBOSE"] = "1"

    # Resolve channel shorthand (shared pre-processing)
    if hasattr(args, "channel") and args.channel:
        from core.nix_eval import resolve_channel_input
        args.input = resolve_channel_input(args.channel)

    # Dispatch to subcommand handler (lazy-loaded for fast startup)
    cmd = args.subcommand
    if cmd in ("query", "q"):
        from cli.commands.query import handle_query
        handle_query(args)
    elif cmd in ("fetch", "f"):
        from cli.commands.fetch import handle_fetch
        handle_fetch(args)
    elif cmd in ("update", "u"):
        from cli.commands.update import handle_update
        handle_update(args)
    elif cmd in ("audit", "a"):
        from cli.commands.audit import handle_audit
        handle_audit(args)
    elif cmd == "adopt":
        from cli.commands.adopt import handle_adopt
        handle_adopt(args)
    elif cmd in ("diff", "d"):
        from cli.commands.diff import handle_diff
        handle_diff(args)
    elif cmd in ("tree", "t"):
        from cli.commands.tree import handle_tree
        handle_tree(args)
    elif cmd in ("tui", "dashboard"):
        from cli.commands.tui import handle_tui
        handle_tui(args)
    elif cmd in ("stats", "summary"):
        from cli.commands.stats import handle_stats
        handle_stats(args)
    elif cmd in ("delete", "rm", "del"):
        from cli.commands.delete import handle_delete
        handle_delete(args)
    elif cmd in ("search", "s"):
        from cli.commands.search import handle_search
        handle_search(args)


if __name__ == "__main__":
    main()
