"""ncp stats — Render comprehensive cache-pins health and readiness dashboard."""
import sys


def handle_stats(args) -> None:
    """Handle the `ncp stats` subcommand."""
    from core.nix_eval import find_cache_pins_file
    from ui.stats import render_stats_dashboard

    pins_file = find_cache_pins_file(args.pins_file)
    if not pins_file:
        print("❌ ERROR: Tidak dapat menemukan berkas modules/_lib/cache-pins.nix", file=sys.stderr)
        sys.exit(1)

    render_stats_dashboard(pins_file)
    sys.exit(0)
