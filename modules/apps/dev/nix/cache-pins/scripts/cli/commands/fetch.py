"""ncp fetch — Download NAR/FOD closure via aria2c to RAM tmpfs and reactively ingest to /nix/store."""

import sys


def handle_fetch(args) -> None:
    """Handle the `ncp fetch` subcommand."""
    from core.cache_client import NixCacheClient
    from downloader.orchestrator import (
        download_fod_target,
        download_single_target,
        download_system_targets,
    )

    cache_client = NixCacheClient(cache_url=args.cache_url)
    dry_run = getattr(args, "dry_run", False)
    verbose = getattr(args, "verbose", False)

    target = getattr(args, "target", None)

    # Default to system closure when no target is provided or target is 'system'
    if (
        getattr(args, "system", False)
        or not target
        or target.lower() in ("system", "sys", "toplevel", "host")
    ):
        download_system_targets(
            cache_client=cache_client,
            hostname=getattr(args, "host", None),
            cache_dir=args.cache_dir,
            split=args.split,
            concurrent=args.concurrent,
            keep_nar=args.keep_nar,
            verbose=verbose,
            dry_run=dry_run,
        )
        sys.exit(0)

    if target.endswith(".drv"):
        download_fod_target(
            drv_path=target,
            cache_dir=args.cache_dir,
            split=args.split,
            concurrent=args.concurrent,
            keep_nar=args.keep_nar,
            verbose=verbose,
            dry_run=dry_run,
        )
        sys.exit(0)

    download_single_target(
        target_input=target,
        cache_client=cache_client,
        nixpkgs_input=args.input if args.input else "nixpkgs",
        cache_dir=args.cache_dir,
        split=args.split,
        concurrent=args.concurrent,
        keep_nar=args.keep_nar,
        verbose=verbose,
        dry_run=dry_run,
    )
