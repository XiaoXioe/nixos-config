"""ncp tui — Launch interactive FZF dashboard for browsing and downloading cache pins."""
import sys


def handle_tui(args) -> None:
    """Handle the `ncp tui` subcommand."""
    from ui.tui import launch_cache_dashboard

    launch_cache_dashboard(
        pins_file_path=args.pins_file,
        cache_url=args.cache_url,
        nixpkgs_input=args.input if args.input else "nixpkgs",
    )
    sys.exit(0)
