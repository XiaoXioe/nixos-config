"""ncp query — Evaluate, audit closure, and inspect Nix binary cache pin status."""
import concurrent.futures
import os
import sys
from typing import Optional

from core.cache.disk_store import LocalDiskCache
from core.cache_client import NixCacheClient
from core.closure import ClosureAuditor
from core.eval.channels import find_cache_pins_file
from core.eval.evaluator import resolve_target_to_store_path
from registry.store import load_cache_pins, write_or_update_pin
from ui.formatters import render_audit_report, render_nix_snippet


def handle_query(args) -> None:
    """Handle the `ncp query` subcommand."""
    concurrency = getattr(args, "concurrency", 16)
    cache_client = NixCacheClient(cache_url=args.cache_url, max_workers=concurrency)

    if args.all:
        _handle_all_mode(cache_client, args.pins_file)
        return

    if not args.target:
        print("❌ ERROR: Diperlukan nama paket. Contoh: ncp query firefox", file=sys.stderr)
        sys.exit(1)

    pins_file = find_cache_pins_file(args.pins_file)
    explicit_input = (
        bool(getattr(args, "channel", None))
        or ("--input" in sys.argv)
        or ("-c" in sys.argv)
        or ("--channel" in sys.argv)
    )

    print(f"🔍 [1/3] Mengevaluasi target '{args.target}'...", file=sys.stderr)
    try:
        store_path, version, main_program = resolve_target_to_store_path(
            target=args.target,
            nixpkgs_input=args.input,
            pins_file=pins_file,
            explicit_input=explicit_input,
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

    print("🔬 [3/3] Menyusun laporan analisis dan template Nix...", file=sys.stderr)
    report_text = render_audit_report(audit, verbose=getattr(args, "verbose", False))
    print(report_text, file=sys.stderr)

    effective_source = args.input
    if not explicit_input and pins_file and pins_file.is_file():
        try:
            pins_data = load_cache_pins(pins_file)
            clean_target = args.target.replace("pkgs.", "").strip()
            if clean_target in pins_data and pins_data[clean_target].get("channel"):
                effective_source = pins_data[clean_target]["channel"]
        except Exception:
            pass

    nix_snippet = render_nix_snippet(audit, source_input=effective_source)
    print(nix_snippet)

    if getattr(args, "write", False):
        if not pins_file:
            print("❌ ERROR: Tidak dapat menemukan cache-pins.nix untuk ditulis.", file=sys.stderr)
            sys.exit(1)
        attr_key = args.target.replace("pkgs.", "").strip()
        write_or_update_pin(pins_file, attr_key, nix_snippet)
        print(f"✨ Berhasil menulis entri '{attr_key}' secara atomik ke {pins_file.name}!", file=sys.stderr)


def _handle_all_mode(cache_client: NixCacheClient, pins_file_path: Optional[str] = None) -> None:
    """Verify hit/miss status for all store paths in cache-pins.nix."""
    pins_file = find_cache_pins_file(pins_file_path)
    if not pins_file:
        print("❌ ERROR: Tidak dapat menemukan berkas modules/_lib/cache-pins.nix", file=sys.stderr)
        sys.exit(1)

    print("================================================================================", file=sys.stderr)
    print(" Memverifikasi seluruh entri di modules/_lib/cache-pins.nix ", file=sys.stderr)
    print(f" Cache Target: {cache_client.summary_display}", file=sys.stderr)
    print("================================================================================", file=sys.stderr)

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
            print(f"  ✅ [HIT]  {name:<22}: {store_path}", file=sys.stderr)
            ok_count += 1
        else:
            print(f"  ❌ [MISS] {name:<22}: {store_path} — TIDAK DITEMUKAN", file=sys.stderr)
            fail_count += 1

    print(f"\nStatus Cache: {ok_count} Tersedia, {fail_count} Tidak Ditemukan", file=sys.stderr)
    sys.exit(1 if fail_count > 0 else 0)
