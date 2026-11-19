"""ncp update — Update flake.lock (or specific input) and pre-fetch system closure via aria2c + reactive ingest."""

import subprocess
import sys

from core.cache_client import NixCacheClient
from core.eval.channels import find_flake_dir
from downloader.orchestrator import download_system_targets


def handle_update(args) -> None:
    """Handle the `ncp update` subcommand."""
    concurrency = getattr(args, "concurrency", 16)
    cache_client = NixCacheClient(cache_url=args.cache_url, max_workers=concurrency)

    flake_dir = find_flake_dir()
    if not flake_dir:
        print("❌ ERROR: Direktori flake (berisi flake.nix) tidak ditemukan.", file=sys.stderr)
        sys.exit(1)

    flake_input = getattr(args, "flake_input", None)
    target = getattr(args, "target", None)

    if not flake_input and target and target.lower() not in ("system", "sys", "toplevel", "host"):
        flake_input = target
    elif not flake_input and "--input" in sys.argv:
        flake_input = getattr(args, "input", None)

    if flake_input and flake_input.lower() == "unstable":
        flake_input = "nixpkgs-unstable"

    print("================================================================================", file=sys.stderr)
    if flake_input:
        print(f"🔄 Memperbarui Flake Input: '{flake_input}' di {flake_dir}...", file=sys.stderr)
        cmd = ["nix", "flake", "update", flake_input]
    else:
        print(f"🔄 Memperbarui seluruh dependensi di flake.lock ({flake_dir})...", file=sys.stderr)
        cmd = ["nix", "flake", "update"]
    print("================================================================================", file=sys.stderr)

    res = subprocess.run(cmd, cwd=str(flake_dir))
    if res.returncode != 0:
        print(f"❌ ERROR: 'nix flake update' gagal dengan kode keluar {res.returncode}.", file=sys.stderr)
        sys.exit(res.returncode)

    print("\n✅ Pembaruan flake.lock selesai dengan sukses!", file=sys.stderr)
    print("🚀 Melanjutkan ke pre-fetching biner closure sistem via aria2c...\n", file=sys.stderr)

    download_system_targets(
        cache_client=cache_client,
        hostname=getattr(args, "host", None),
        cache_dir=getattr(args, "cache_dir", None),
        split=getattr(args, "split", 8),
        concurrent=getattr(args, "concurrent", 4),
        keep_nar=getattr(args, "keep_nar", False),
        verbose=getattr(args, "verbose", False),
        dry_run=getattr(args, "dry_run", False),
    )
    sys.exit(0)
