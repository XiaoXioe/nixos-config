"""ncp tree — Interactively browse Nix store path dependency graph via nix-tree."""
import os
from pathlib import Path
import subprocess
import sys


def handle_tree(args) -> None:
    """Handle the `ncp tree` subcommand."""
    if not args.target:
        print("❌ ERROR: Tentukan nama paket atau store path. Contoh: ncp tree aria2", file=sys.stderr)
        sys.exit(1)

    from core.nix_eval import find_cache_pins_file, resolve_target_to_store_path

    pins_file = find_cache_pins_file(args.pins_file)

    print(f"🔍 Mengevaluasi target '{args.target}'...", file=sys.stderr)
    try:
        store_path, version, _ = resolve_target_to_store_path(
            target=args.target,
            nixpkgs_input=args.input if args.input else "nixpkgs",
            pins_file=pins_file,
        )
    except Exception as e:
        print(f"❌ ERROR: {e}", file=sys.stderr)
        sys.exit(1)

    print(f"🌳 Membuka visualisasi closure grafik untuk {store_path} (v{version})...", file=sys.stderr)

    # 1. In non-interactive mode (e.g. pipe, script, subshell), print plain text tree
    if not sys.stdout.isatty() or os.environ.get("TERM") in (None, "", "dumb"):
        try:
            subprocess.run(["nix-store", "-q", "--tree", store_path])
            sys.exit(0)
        except Exception as e:
            print(f"❌ ERROR: {e}", file=sys.stderr)
            sys.exit(1)

    # 2. In interactive TTY, launch nix-tree TUI
    try:
        cmd = ["nix-tree", store_path]
        res = subprocess.run(cmd)
        sys.exit(res.returncode)
    except FileNotFoundError:
        print("⚠️  Tool 'nix-tree' belum aktif di PATH (akan aktif setelah 'nh os switch').", file=sys.stderr)
        print("📋 Menampilkan pohon dependensi menggunakan 'nix-store --query --tree':\n", file=sys.stderr)
        try:
            subprocess.run(["nix-store", "-q", "--tree", store_path])
        except Exception as e:
            print(f"❌ ERROR: {e}", file=sys.stderr)
            sys.exit(1)
