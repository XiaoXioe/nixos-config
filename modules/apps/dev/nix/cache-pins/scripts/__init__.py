"""nix-cache-pin (ncp) — Unified CLI suite for Nix binary cache pin management.

Sub-packages:
    cli: Unified CLI entry point, subcommand routing, and argument parsing.
    core: Data models, Nix evaluation, HTTP client, and DAG closure traversal.
    registry: CRUD operations for cache-pins.nix, codebase pin auditing, and module adoption.
    downloader: RAM tmpfs lifecycle, aria2c execution, and nix-store realisation.
    ui: CLI formatters, statistics dashboard, FZF TUI, and version picker.
"""
