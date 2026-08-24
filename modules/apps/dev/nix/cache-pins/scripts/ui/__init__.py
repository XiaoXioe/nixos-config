"""UI package for formatters, statistics dashboard, FZF TUI, and version search picker."""

from ui.formatters import format_bytes, render_audit_report, render_nix_snippet
from ui.stats import render_stats_dashboard
from ui.tui import launch_cache_dashboard
from ui.version_picker import interactive_version_picker

__all__ = [
    "format_bytes",
    "interactive_version_picker",
    "launch_cache_dashboard",
    "render_audit_report",
    "render_nix_snippet",
    "render_stats_dashboard",
]
