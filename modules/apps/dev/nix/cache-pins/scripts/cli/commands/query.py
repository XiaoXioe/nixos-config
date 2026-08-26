"""ncp query — Evaluate, audit closure, and inspect Nix binary cache pin status."""
import concurrent.futures
import os
import sys
from typing import Optional


def handle_query(args) -> None:
    """Handle the `ncp query` subcommand."""
    from core.cache_client import NixCacheClient

    cache_client = NixCacheClient(cache_url=args.cache_url)

    if args.all:
        _handle_all_mode(cache_client, args.pins_file)
        return

    if not args.target:
        print("❌ ERROR: Diperlukan nama paket. Contoh: ncp query firefox", file=sys.stderr)
        sys.exit(1)

    from core.closure import ClosureAuditor
    from core.nix_eval import find_cache_pins_file, resolve_target_to_store_path
    from ui.formatters import render_audit_report, render_nix_snippet

    pins_file = find_cache_pins_file(args.pins_file)

    print(f"🔍 [1/3] Mengevaluasi target '{args.target}' (Channel: {args.input})...", file=sys.stderr)
    try:
        store_path, version, main_program = resolve_target_to_store_path(
            target=args.target, nixpkgs_input=args.input, pins_file=pins_file,
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
            target_name=args.target, store_path=store_path,
            version=version, main_program=main_program,
        )
    except Exception as e:
        print(f"❌ ERROR: {e}", file=sys.stderr)
        sys.exit(1)

    print("🔬 [3/3] Menyusun laporan analisis dan template Nix...", file=sys.stderr)
    report_text = render_audit_report(audit, verbose=getattr(args, "verbose", False))
    print(report_text, file=sys.stderr)

    nix_snippet = render_nix_snippet(audit, source_input=args.input)
    print(nix_snippet)

    if getattr(args, "write", False):
        if not pins_file:
            print("❌ ERROR: Tidak dapat menemukan cache-pins.nix untuk ditulis.", file=sys.stderr)
            sys.exit(1)
        from registry.store import write_or_update_pin
        attr_key = args.target.replace("pkgs.", "")
        write_or_update_pin(pins_file, attr_key, nix_snippet)
        print(f"✨ Berhasil menulis entri '{attr_key}' ke {pins_file.name}!", file=sys.stderr)


def _handle_all_mode(cache_client, pins_file_path: Optional[str] = None) -> None:
    """Verify hit/miss status for all store paths in cache-pins.nix."""
    from core.nix_eval import find_cache_pins_file
    from registry.store import load_cache_pins

    pins_file = find_cache_pins_file(pins_file_path)
    if not pins_file:
        print("❌ ERROR: Tidak dapat menemukan berkas modules/_lib/cache-pins.nix", file=sys.stderr)
        sys.exit(1)

    print("============================================================", file=sys.stderr)
    print(" Memverifikasi seluruh entri di modules/_lib/cache-pins.nix ", file=sys.stderr)
    print(f" Cache Target: {cache_client.summary_display}", file=sys.stderr)
    print("============================================================", file=sys.stderr)

    pins_data = load_cache_pins(pins_file)
    if not pins_data:
        print("❌ ERROR: Tidak ada entri valid ditemukan di cache-pins.nix", file=sys.stderr)
        sys.exit(1)

    items = [
        (name, data["storePath"])
        for name, data in pins_data.items()
        if isinstance(data, dict) and "storePath" in data
    ]

    ok_count, fail_count = 0, 0

    def check_entry(item):
        name, store_path = item
        h = os.path.basename(store_path).split("-")[0]
        return name, store_path, cache_client.check_hit(h)

    with concurrent.futures.ThreadPoolExecutor(max_workers=cache_client.max_workers) as executor:
        results = list(executor.map(check_entry, items))

    for name, store_path, hit in results:
        if hit:
            print(f"  ✅ [HIT]  {name}: {store_path}", file=sys.stderr)
            ok_count += 1
        else:
            print(f"  ❌ [MISS] {name}: {store_path} — TIDAK DITEMUKAN", file=sys.stderr)
            fail_count += 1

    print(f"\nStatus Cache: {ok_count} Tersedia, {fail_count} Tidak Ditemukan", file=sys.stderr)
    sys.exit(1 if fail_count > 0 else 0)
