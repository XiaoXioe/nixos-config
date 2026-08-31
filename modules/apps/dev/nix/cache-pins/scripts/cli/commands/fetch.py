"""ncp fetch — Download NAR closure via aria2c to RAM tmpfs and ingest to /nix/store."""

import sys


def handle_fetch(args) -> None:
    """Handle the `ncp fetch` subcommand."""
    from core.cache_client import NixCacheClient
    from downloader.orchestrator import download_batch_targets, download_single_target

    cache_client = NixCacheClient(cache_url=args.cache_url)
    explicit_input = (
        bool(getattr(args, "channel", None))
        or ("--input" in sys.argv)
        or ("-c" in sys.argv)
        or ("--channel" in sys.argv)
    )
    dry_run = getattr(args, "dry_run", False)
    verbose = getattr(args, "verbose", False)

    if getattr(args, "all_active", False) or getattr(args, "all_pins", False):
        download_batch_targets(
            all_pins=getattr(args, "all_pins", False),
            cache_client=cache_client,
            pins_file_path=args.pins_file,
            cache_dir=args.cache_dir,
            split=args.split,
            concurrent=args.concurrent,
            keep_nar=args.keep_nar,
            verbose=verbose,
            dry_run=dry_run,
        )
        sys.exit(0)

    if getattr(args, "system", False) or (
        args.target and args.target.lower() in ("system", "sys", "toplevel", "host")
    ):
        from downloader.orchestrator import download_system_targets

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

    if args.target and args.target.endswith(".drv"):
        from downloader.orchestrator import download_fod_target

        download_fod_target(
            drv_path=args.target,
            cache_dir=args.cache_dir,
            split=args.split,
            concurrent=args.concurrent,
            keep_nar=args.keep_nar,
            verbose=verbose,
            dry_run=dry_run,
        )
        sys.exit(0)

    if not args.target:
        print(
            "❌ ERROR: Diperlukan nama paket, target 'system', atau flag --all-active/--all-pins.",
            file=sys.stderr,
        )
        print("   Contoh: ncp fetch firefox", file=sys.stderr)
        print("   Contoh: ncp fetch system", file=sys.stderr)
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
        explicit_input=explicit_input,
        verbose=verbose,
        dry_run=dry_run,
    )
