"""ncp adopt — Adopt a package from pkgs into cache-pins and refactor consumer modules."""
from pathlib import Path
import sys
from typing import List, Optional


def handle_adopt(args) -> None:
    """Handle the `ncp adopt` subcommand."""
    from core.cache_client import NixCacheClient
    from core.closure import ClosureAuditor
    from core.nix_eval import find_cache_pins_file, resolve_target_to_store_path
    from registry.adopt import adopt_module_pin, find_modules_referencing_pkg
    from registry.store import write_or_update_pin
    from ui.formatters import render_nix_snippet

    pins_file = find_cache_pins_file(args.pins_file)
    if not pins_file:
        print("❌ ERROR: Tidak dapat menemukan berkas modules/_lib/cache-pins.nix", file=sys.stderr)
        sys.exit(1)

    clean_attr = args.target.replace("pkgs.", "")

    target_modules: List[Path] = []
    if getattr(args, "module_path", None):
        p = Path(args.module_path)
        if not p.is_file():
            print(f"❌ ERROR: Berkas modul target tidak ditemukan: {args.module_path}", file=sys.stderr)
            sys.exit(1)
        target_modules.append(p.resolve())
    else:
        print(f"🔍 Mencari file modul yang mereferensikan 'pkgs.{clean_attr}'...", file=sys.stderr)
        target_modules = find_modules_referencing_pkg(clean_attr)
        if not target_modules:
            print(f"❌ ERROR: Tidak ditemukan modul yang memanggil 'pkgs.{clean_attr}'.", file=sys.stderr)
            print("   Harap tentukan path file modul secara eksplisit, contoh:", file=sys.stderr)
            print(f"   ncp adopt {clean_attr} modules/path/to/module.nix", file=sys.stderr)
            sys.exit(1)

    nixpkgs_input = args.input if args.input else "nixpkgs"
    cache_client = NixCacheClient(cache_url=args.cache_url)

    print(f"📦 [1/3] Mengevaluasi store path upstream untuk '{clean_attr}' ({nixpkgs_input})...", file=sys.stderr)
    try:
        store_path, version, main_program = resolve_target_to_store_path(
            target=clean_attr,
            nixpkgs_input=nixpkgs_input,
            pins_file=pins_file,
        )
    except Exception as e:
        print(f"❌ ERROR: {e}", file=sys.stderr)
        sys.exit(1)

    print("🌐 [2/3] Mengambil closure metadata dari binary cache...", file=sys.stderr)
    auditor = ClosureAuditor(cache_client)
    audit = auditor.audit_closure(
        target_name=clean_attr,
        store_path=store_path,
        version=version,
        main_program=main_program,
    )
    nix_snippet = render_nix_snippet(audit, source_input=nixpkgs_input)
    write_or_update_pin(pins_file, clean_attr, nix_snippet)
    print(f"  ✅ Pin '{clean_attr}' berhasil disimpan di {pins_file.name}!", file=sys.stderr)

    print(f'🪄 [3/3] Me-refactor modul target ke (selfLib.fetchCachePinned "{clean_attr}")...', file=sys.stderr)
    for mod in target_modules:
        if adopt_module_pin(mod, clean_attr):
            print(f"  ✨ Berhasil memperbarui: {mod.name}", file=sys.stderr)
        else:
            print(f"  ⚠️  Tidak ada perubahan pada: {mod.name}", file=sys.stderr)

    print("\n🎉 Sukses! Modul telah diadopsi ke sistem cache-pins.", file=sys.stderr)
    sys.exit(0)
