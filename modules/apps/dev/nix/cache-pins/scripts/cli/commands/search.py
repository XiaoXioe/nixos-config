"""ncp search — Search package versions via FZF (NixHub, Git tags, Flake inputs)."""
import sys


def handle_search(args) -> None:
    """Handle the `ncp search` subcommand."""
    from core.cache_client import NixCacheClient
    from core.closure import ClosureAuditor
    from core.nix_eval import evaluate_upstream_package
    from ui.formatters import render_audit_report, render_nix_snippet
    from ui.version_picker import interactive_version_picker

    # search adalah eksplorasi multi-sumber via FZF — flag -c tidak relevan
    if getattr(args, "channel", None):
        print(
            "⚠️  Flag '-c/--channel' diabaikan untuk subcommand 'search'. "
            "FZF sudah menampilkan versi dari semua channel.",
            file=sys.stderr,
        )

    target_input = args.target
    if not target_input:
        try:
            target_input = input("Masukkan nama paket yang ingin dicari versinya: ").strip()
        except (EOFError, KeyboardInterrupt):
            sys.exit(0)
        if not target_input:
            sys.exit(0)

    selected_version = interactive_version_picker(target_input, cache_url=args.cache_url)
    if not selected_version:
        print("Pencarian versi dibatalkan.", file=sys.stderr)
        sys.exit(0)

    flake_input = selected_version["flake_input"]
    attr = selected_version["attr"]
    pname = selected_version.get("pname")
    print(f"🎯 Versi terpilih: v{selected_version['version']} ({flake_input})", file=sys.stderr)

    cache_client = NixCacheClient(cache_url=args.cache_url)

    print(f"🔍 Mengevaluasi '{attr}' dari {flake_input}...", file=sys.stderr)
    if "github:NixOS/nixpkgs/" in flake_input and len(flake_input.split("/")[-1]) >= 32:
        print("   ⏳ Mengunduh & mengekstrak commit Git dari GitHub (harap tunggu beberapa saat)...", file=sys.stderr)

    try:
        store_path, version, main_program = evaluate_upstream_package(
            target_key=attr,
            nixpkgs_input=flake_input,
            pname=pname,
        )
        if not store_path:
            raise RuntimeError(
                f"Tidak dapat menemukan store path untuk '{attr}' dari {flake_input}."
            )
    except Exception as e:
        print(f"❌ ERROR: {e}", file=sys.stderr)
        sys.exit(1)

    print(
        f"🌐 Mengambil metadata & pohon dependensi dari binary cache ({cache_client.summary_display})...",
        file=sys.stderr,
    )
    try:
        auditor = ClosureAuditor(cache_client)
        audit = auditor.audit_closure(
            target_name=attr,
            store_path=store_path,
            version=version,
            main_program=main_program,
        )
    except Exception as e:
        print(f"❌ ERROR: {e}", file=sys.stderr)
        sys.exit(1)

    report_text = render_audit_report(audit, verbose=False)
    print(report_text, file=sys.stderr)

    nix_snippet = render_nix_snippet(audit, source_input=flake_input)
    print(nix_snippet)
