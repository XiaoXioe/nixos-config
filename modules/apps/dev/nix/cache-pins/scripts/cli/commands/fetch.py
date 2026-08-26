"""ncp fetch — Download NAR closure via aria2c to RAM tmpfs and ingest to /nix/store."""
import os
import sys
from typing import Optional


def handle_fetch(args) -> None:
    """Handle the `ncp fetch` subcommand."""
    from core.cache_client import NixCacheClient
    from downloader.orchestrator import download_batch_targets, download_single_target

    cache_client = NixCacheClient(cache_url=args.cache_url)

    if getattr(args, "all_active", False) or getattr(args, "all_pins", False):
        download_batch_targets(
            all_pins=getattr(args, "all_pins", False),
            cache_client=cache_client,
            pins_file_path=args.pins_file,
            cache_dir=args.cache_dir,
            split=args.split,
            concurrent=args.concurrent,
            keep_nar=args.keep_nar,
        )
        sys.exit(0)

    if not args.target:
        print("❌ ERROR: Diperlukan nama paket atau flag --all-active/--all-pins. Contoh: ncp fetch firefox", file=sys.stderr)
        sys.exit(1)

    download_single_target(
        target_input=args.target,
        cache_client=cache_client,
        nixpkgs_input=args.input if args.input else "nixpkgs",
        pins_file_path=args.pins_file,
        cache_dir=args.cache_dir,
        split=args.split,
        concurrent=args.concurrent,
        keep_nar=args.keep_nar,
    )
