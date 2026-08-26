"""ncp update — Check and update cache pins from upstream Nixpkgs channels."""
import os
from pathlib import Path
import sys
from typing import Optional


def handle_update(args) -> None:
    """Handle the `ncp update` subcommand."""
    from core.cache_client import NixCacheClient

    cache_client = NixCacheClient(cache_url=args.cache_url)
    explicit_input = bool(getattr(args, "channel", None)) or ("--input" in sys.argv) or ("-c" in sys.argv) or ("--channel" in sys.argv)
    force = getattr(args, "force", False)
    write_to_file = getattr(args, "write", False)
    version_only = getattr(args, "version_only", False)

    if getattr(args, "all", False):
        _handle_update_all(
            cache_client=cache_client,
            nixpkgs_input=args.input,
            pins_file_path=args.pins_file,
            force=force,
            explicit_input=explicit_input,
            write_to_file=write_to_file,
            version_only=version_only,
        )
        sys.exit(0)

    if not args.target:
        print("❌ ERROR: Tentukan nama paket yang ingin diperbarui atau gunakan flag '--all'.", file=sys.stderr)
        print("   Contoh: ncp update aria2 -w", file=sys.stderr)
        print("   Contoh: ncp update --all -w", file=sys.stderr)
        sys.exit(1)

    _handle_update_single(
        target_key=args.target,
        cache_client=cache_client,
        nixpkgs_input=args.input,
        pins_file_path=args.pins_file,
        force=force,
        explicit_input=explicit_input,
        write_to_file=write_to_file,
        version_only=version_only,
    )
    sys.exit(0)


def _handle_update_single(
    target_key: str,
    cache_client,
    nixpkgs_input: str,
    pins_file_path: Optional[str] = None,
    force: bool = False,
    explicit_input: bool = False,
    write_to_file: bool = False,
    version_only: bool = False,
) -> None:
    """Check and update a single pin from upstream channel if binary cache HIT exists."""
    from core.closure import ClosureAuditor
    from core.nix_eval import (
        compare_versions,
        evaluate_upstream_package,
        find_cache_pins_file,
        resolve_channel_input,
    )
    from registry.store import load_cache_pins, load_pin_sources, write_or_update_pin
    from ui.formatters import render_audit_report, render_nix_snippet

    pins_file = find_cache_pins_file(pins_file_path)
    if not pins_file:
        print("❌ ERROR: Tidak dapat menemukan modules/_lib/cache-pins.nix", file=sys.stderr)
        sys.exit(1)

    attr_key = target_key.replace("pkgs.", "")
    pins_data = load_cache_pins(pins_file)
    pin_sources = load_pin_sources(pins_file)

    current_data = pins_data.get(attr_key, {})
    current_store_path = current_data.get("storePath", "")
    current_version = current_data.get("version", "unknown")
    declared_channel = current_data.get("channel")

    pname = current_data.get("pname")

    if explicit_input:
        effective_input = nixpkgs_input
    elif declared_channel:
        effective_input = resolve_channel_input(declared_channel)
    elif pin_sources.get(attr_key):
        effective_input = resolve_channel_input(pin_sources.get(attr_key))
    else:
        effective_input = nixpkgs_input

    print(f"🔍 Memeriksa pembaruan upstream untuk '{attr_key}' dari {effective_input}...", file=sys.stderr)

    new_store_path, new_version, main_program = evaluate_upstream_package(
        attr_key, effective_input, pname=pname
    )

    if not new_store_path or not new_store_path.startswith("/nix/store/"):
        print(f"❌ ERROR: Gagal mengevaluasi outPath upstream untuk '{attr_key}'", file=sys.stderr)
        sys.exit(1)

    if new_store_path == current_store_path:
        print(f"✅ [{attr_key}] Sudah versi terbaru & hash identik (v{current_version})", file=sys.stderr)
        sys.exit(0)

    old_hash = os.path.basename(current_store_path).split("-")[0] if current_store_path else "none"
    new_hash = os.path.basename(new_store_path).split("-")[0]

    is_rebuild = (new_version == current_version) and (current_version != "unknown")

    if is_rebuild and version_only:
        print(
            f"⏳ [{attr_key}] Rebuild baru terdeteksi (hash: {old_hash[:7]} ➔ {new_hash[:7]}), tapi versi sama (v{current_version}). Dilewati (--version-only).",
            file=sys.stderr,
        )
        sys.exit(0)

    # Downgrade guard
    if current_version != "unknown" and new_version != "unknown":
        cmp = compare_versions(new_version, current_version)
        if cmp < 0 and not force:
            print(
                f"⚠️  Pemberitahuan: Versi upstream ({effective_input}) v{new_version} lebih rendah dari versi pin saat ini (v{current_version}).",
                file=sys.stderr,
            )
            print("   Pembaruan dibatalkan untuk mencegah accidental downgrade. Gunakan -f / --force jika ingin downgrade.", file=sys.stderr)
            sys.exit(1)

    if not cache_client.check_hit(new_hash):
        print(f"⚠️  Pemberitahuan: Biner upstream untuk {new_store_path} belum tersedia di binary cache (MISS).", file=sys.stderr)
        print("   Pin lama dipertahankan agar tidak terjadi kompilasi lokal.", file=sys.stderr)
        sys.exit(1)

    auditor = ClosureAuditor(cache_client)
    audit = auditor.audit_closure(
        target_name=attr_key,
        store_path=new_store_path,
        version=new_version,
        main_program=main_program,
    )

    report_text = render_audit_report(audit, verbose=False)
    print(report_text, file=sys.stderr)

    nix_snippet = render_nix_snippet(audit, source_input=effective_input)

    if write_to_file:
        write_or_update_pin(pins_file, attr_key, nix_snippet)
        if is_rebuild:
            print(f"🔄 Berhasil memperbarui REBUILD hash '{attr_key}' di {pins_file.name} (hash: {old_hash[:7]} ➔ {new_hash[:7]})!", file=sys.stderr)
        else:
            print(f"🚀 Berhasil memperbarui VERSI '{attr_key}' ke v{new_version} di {pins_file.name}!", file=sys.stderr)
    else:
        print(nix_snippet)
        if is_rebuild:
            print(f"\n🔄 [REBUILD / HASH UPDATE] Versi tetap v{current_version}, tapi hash berubah ({old_hash[:7]} ➔ {new_hash[:7]}).", file=sys.stderr)
            print("   (Patch / dependensi upstream telah di-rebuild oleh Hydra)", file=sys.stderr)
        else:
            print(f"\n🚀 [VERSION BUMP] Versi naik dari v{current_version} ➔ v{new_version}.", file=sys.stderr)
        print(f"💡 Mode Dry-Run: Entri di {pins_file.name} TIDAK diubah.", file=sys.stderr)
        print(f"   Gunakan 'ncp update {attr_key} -w' untuk menyimpan perubahan ke berkas.", file=sys.stderr)


def _handle_update_all(
    cache_client,
    nixpkgs_input: str,
    pins_file_path: Optional[str] = None,
    force: bool = False,
    explicit_input: bool = False,
    write_to_file: bool = False,
    version_only: bool = False,
) -> None:
    """Check and update all pins from upstream channel in batch with source retention and downgrade guard."""
    from core.closure import ClosureAuditor
    from core.nix_eval import (
        compare_versions,
        evaluate_upstream_package,
        find_cache_pins_file,
        resolve_channel_input,
    )
    from registry.store import load_cache_pins, load_pin_sources, write_or_update_pin
    from ui.formatters import render_nix_snippet

    pins_file = find_cache_pins_file(pins_file_path)
    if not pins_file:
        print("❌ ERROR: Tidak dapat menemukan modules/_lib/cache-pins.nix", file=sys.stderr)
        sys.exit(1)

    pins_data = load_cache_pins(pins_file)
    if not pins_data:
        print("❌ ERROR: Tidak ada entri di cache-pins.nix", file=sys.stderr)
        sys.exit(1)

    pin_sources = load_pin_sources(pins_file)

    mode_title = "[PERMANEN / WRITE MODE]" if write_to_file else "[DRY-RUN / PREVIEW MODE]"

    print("============================================================", file=sys.stderr)
    print(f" Memeriksa pembaruan upstream untuk {len(pins_data)} paket {mode_title} ", file=sys.stderr)
    if explicit_input:
        print(f" Global Upstream Input : {nixpkgs_input} (Override mode)", file=sys.stderr)
    else:
        print(" Multi-Source Channel  : Otomatis mendeteksi atribut channel per pin", file=sys.stderr)
    if version_only:
        print(" Filter Kebijakan      : --version-only (Mengabaikan rebuild berversi sama)", file=sys.stderr)
    print(f" Binary Cache Target   : {cache_client.summary_display}", file=sys.stderr)
    print("============================================================", file=sys.stderr)

    auditor = ClosureAuditor(cache_client)
    updated_count, skipped_count, ready_count = 0, 0, 0

    for key, data in sorted(pins_data.items()):
        current_store_path = data.get("storePath", "")
        current_version = data.get("version", "unknown")
        declared_channel = data.get("channel")
        pname = data.get("pname")

        if explicit_input:
            effective_input = nixpkgs_input
        elif declared_channel:
            effective_input = resolve_channel_input(declared_channel)
        elif pin_sources.get(key):
            effective_input = resolve_channel_input(pin_sources.get(key))
        else:
            effective_input = nixpkgs_input

        # Dynamic progress feedback in terminal (only on interactive TTY)
        is_tty = sys.stderr.isatty()
        if is_tty:
            channel_label = declared_channel or (pin_sources.get(key) if not explicit_input else nixpkgs_input)
            print(f"  ⏳ [{key}] Memeriksa upstream ({channel_label})...", file=sys.stderr, end="\r", flush=True)

        new_store_path, new_version, main_program = evaluate_upstream_package(
            key, effective_input, pname=pname
        )

        if is_tty:
            # Clear status line before printing final result
            print("\033[2K\r", file=sys.stderr, end="", flush=True)

        if not new_store_path or not new_store_path.startswith("/nix/store/"):
            print(f"  ⚠️  [{key}] Gagal evaluasi upstream ({effective_input}).", file=sys.stderr)
            continue

        if new_store_path == current_store_path:
            print(f"  ✅ [{key}] Sudah versi terbaru & hash identik (v{current_version}) [{declared_channel or effective_input}]", file=sys.stderr)
            continue

        old_hash = os.path.basename(current_store_path).split("-")[0] if current_store_path else "none"
        new_hash = os.path.basename(new_store_path).split("-")[0]

        is_rebuild = (new_version == current_version) and (current_version != "unknown")

        if is_rebuild and version_only:
            print(
                f"  ⏳ [{key}] Rebuild baru terdeteksi (hash: {old_hash[:7]} ➔ {new_hash[:7]}), tapi versi sama (v{current_version}). Dilewati (--version-only).",
                file=sys.stderr,
            )
            skipped_count += 1
            continue

        # Downgrade guard
        if current_version != "unknown" and new_version != "unknown":
            cmp = compare_versions(new_version, current_version)
            if cmp < 0 and not force:
                print(
                    f"  ⏳ [{key}] Upstream ({effective_input}) v{new_version} < v{current_version} (mencegah downgrade). Dilewati.",
                    file=sys.stderr,
                )
                skipped_count += 1
                continue

        if not cache_client.check_hit(new_hash):
            print(f"  ⏳ [{key}] Upstream baru ada (v{new_version}), tapi belum ready di binary cache (MISS). Dilewati.", file=sys.stderr)
            skipped_count += 1
            continue

        if write_to_file:
            audit = auditor.audit_closure(
                target_name=key,
                store_path=new_store_path,
                version=new_version,
                main_program=main_program,
            )
            nix_snippet = render_nix_snippet(audit, source_input=effective_input)
            write_or_update_pin(pins_file, key, nix_snippet)
            if is_rebuild:
                print(f"  🔄 [{key}] REBUILD DIPERBARUI: v{current_version} (hash: {old_hash[:7]} ➔ {new_hash[:7]}) [{declared_channel or effective_input}]", file=sys.stderr)
            else:
                print(f"  🚀 [{key}] VERSI DIPERBARUI: v{current_version} ➔ v{new_version} (hash: {old_hash[:7]} ➔ {new_hash[:7]}) [{declared_channel or effective_input}]", file=sys.stderr)
            updated_count += 1
        else:
            if is_rebuild:
                print(f"  🔄 [{key}] TERSEDIA REBUILD / HASH UPDATE: v{current_version} (hash: {old_hash[:7]} ➔ {new_hash[:7]}) [{declared_channel or effective_input}]", file=sys.stderr)
            else:
                print(f"  ✨ [{key}] TERSEDIA VERSI BARU: v{current_version} ➔ v{new_version} (hash: {old_hash[:7]} ➔ {new_hash[:7]}) [{declared_channel or effective_input}]", file=sys.stderr)
            ready_count += 1

    print("------------------------------------------------------------", file=sys.stderr)
    if write_to_file:
        print(f"🎉 Selesai! {updated_count} paket berhasil disimpan ke {pins_file.name}.", file=sys.stderr)
    else:
        print(f"📊 Ringkasan Dry-Run: Ditemukan {ready_count} pembaruan yang siap diterapkan.", file=sys.stderr)
        print(f"💡 Untuk menyimpan pembaruan ke {pins_file.name}, jalankan kembali dengan flag '-w' / '--write':", file=sys.stderr)
        print("   ncp update --all -w", file=sys.stderr)
