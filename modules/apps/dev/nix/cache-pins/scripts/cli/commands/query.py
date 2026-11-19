"""ncp query — Evaluate package from Nixpkgs and inspect binary cache closure status."""

import sys

from core.cache_client import NixCacheClient
from core.closure import ClosureAuditor
from core.eval.evaluator import resolve_target_to_store_path
from ui.formatters import render_audit_report


def handle_query(args) -> None:
    """Handle the `ncp query` subcommand."""
    if not args.target:
        print("❌ ERROR: Diperlukan nama paket atau store path. Contoh: ncp query firefox", file=sys.stderr)
        sys.exit(1)

    concurrency = getattr(args, "concurrency", 16)
    cache_client = NixCacheClient(cache_url=args.cache_url, max_workers=concurrency)

    print(f"🔍 [1/3] Mengevaluasi target '{args.target}' dari '{args.input}'...", file=sys.stderr)
    try:
        store_path, version, main_program = resolve_target_to_store_path(
            target=args.target,
            nixpkgs_input=args.input,
        )
    except Exception as e:
        print(f"❌ ERROR: {e}", file=sys.stderr)
        sys.exit(1)

    print(
        f"🌐 [2/3] Mengambil metadata & pohon dependensi dari binary cache ({cache_client.summary_display})...",
        file=sys.stderr,
    )
    try:
        auditor = ClosureAuditor(cache_client)
        audit = auditor.audit_closure(
            target_name=args.target,
            store_path=store_path,
            version=version,
            main_program=main_program,
        )
    except Exception as e:
        print(f"❌ ERROR: {e}", file=sys.stderr)
        sys.exit(1)

    print("🔬 [3/3] Menyusun laporan analisis closure binary cache...", file=sys.stderr)
    report_text = render_audit_report(audit, verbose=getattr(args, "verbose", False))
    print(report_text, file=sys.stderr)
