"""ncp update — Check and update cache pins from upstream Nixpkgs channels with batch evaluation."""
from collections import defaultdict
import os
from pathlib import Path
import sys
from typing import Dict, List, Optional, Tuple

from core.cache.disk_store import LocalDiskCache
from core.cache_client import NixCacheClient
from core.closure import ClosureAuditor
from core.eval.channels import (
    find_cache_pins_file,
    normalize_channel_name,
    resolve_channel_input,
)
from core.eval.evaluator import evaluate_batch, evaluate_single_package
from core.eval.resolver import compare_versions
from core.models import PackageMeta, UpdateResult, UpdateType
from registry.store import (
    load_cache_pins,
    load_pin_sources,
    write_or_update_pin,
    write_or_update_pins_batch,
)
from ui.formatters import render_audit_report, render_nix_snippet


def handle_update(args) -> None:
    """Handle the `ncp update` subcommand."""
    concurrency = getattr(args, "concurrency", 16)
    cache_client = NixCacheClient(cache_url=args.cache_url, max_workers=concurrency)
    explicit_input = (
        bool(getattr(args, "channel", None))
        or ("--input" in sys.argv)
        or ("-c" in sys.argv)
        or ("--channel" in sys.argv)
    )
    force = getattr(args, "force", False)
    write_to_file = getattr(args, "write", False)
    version_only = getattr(args, "version_only", False)
    refresh = getattr(args, "refresh", False)

    if getattr(args, "all", False):
        _handle_update_all(
            cache_client=cache_client,
            nixpkgs_input=args.input,
            pins_file_path=args.pins_file,
            force=force,
            explicit_input=explicit_input,
            write_to_file=write_to_file,
            version_only=version_only,
            refresh=refresh,
        )
        sys.exit(0)

    if getattr(args, "system", False) or (args.target and args.target.lower() in ("system", "sys", "toplevel", "host")):
        _handle_update_system(args, cache_client)
        sys.exit(0)

    if not args.target:
        print("❌ ERROR: Tentukan nama paket, target 'system', atau gunakan flag '--all'.", file=sys.stderr)
        print("   Contoh: ncp update aria2 -w", file=sys.stderr)
        print("   Contoh: ncp update system", file=sys.stderr)
        print("   Contoh: ncp update system --input nix-cachyos-kernel", file=sys.stderr)
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
        refresh=refresh,
    )
    sys.exit(0)


def _handle_update_single(
    target_key: str,
    cache_client: NixCacheClient,
    nixpkgs_input: str,
    pins_file_path: Optional[str] = None,
    force: bool = False,
    explicit_input: bool = False,
    write_to_file: bool = False,
    version_only: bool = False,
    refresh: bool = False,
) -> None:
    """Check and update a single pin from upstream channel if binary cache HIT exists."""
    pins_file = find_cache_pins_file(pins_file_path)
    if not pins_file:
        print("❌ ERROR: Tidak dapat menemukan modules/_lib/cache-pins.nix", file=sys.stderr)
        sys.exit(1)

    attr_key = target_key.replace("pkgs.", "").strip()
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

    disk_cache = LocalDiskCache()
    meta = disk_cache.get(effective_input, attr_key, bypass_cache=refresh)

    if not meta:
        print(f"🔍 Mengevaluasi upstream untuk '{attr_key}' dari {effective_input}...", file=sys.stderr)
        sp, ver, main_prog = evaluate_single_package(
            target_key=attr_key,
            nixpkgs_input=effective_input,
            pname=pname,
        )
        if sp:
            meta = PackageMeta(
                store_path=sp,
                version=ver,
                main_program=main_prog,
                pname=pname,
                channel=effective_input,
            )
            disk_cache.set_batch(effective_input, {attr_key: meta})

    if not meta or not meta.store_path:
        print(f"❌ ERROR: Gagal mengevaluasi outPath upstream untuk '{attr_key}' dari {effective_input}", file=sys.stderr)
        sys.exit(1)

    new_store_path = meta.store_path
    new_version = meta.version
    main_program = meta.main_program

    if new_store_path == current_store_path:
        print(f"✅ [{attr_key}] Sudah versi terbaru & hash identik (v{current_version}) [{declared_channel or effective_input}]", file=sys.stderr)
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
        else:
            print(f"\n🚀 [VERSION BUMP] Versi naik dari v{current_version} ➔ v{new_version}.", file=sys.stderr)
        print(f"💡 Mode Dry-Run: Entri di {pins_file.name} TIDAK diubah.", file=sys.stderr)
        print(f"   Gunakan 'ncp update {attr_key} -w' untuk menyimpan perubahan ke berkas.", file=sys.stderr)


def _handle_update_all(
    cache_client: NixCacheClient,
    nixpkgs_input: str,
    pins_file_path: Optional[str] = None,
    force: bool = False,
    explicit_input: bool = False,
    write_to_file: bool = False,
    version_only: bool = False,
    refresh: bool = False,
) -> None:
    """Check and update all pins using fast batch evaluation and persistent revision caching."""
    pins_file = find_cache_pins_file(pins_file_path)
    if not pins_file:
        print("❌ ERROR: Tidak dapat menemukan modules/_lib/cache-pins.nix", file=sys.stderr)
        sys.exit(1)

    pins_data = load_cache_pins(pins_file)
    if not pins_data:
        print("❌ ERROR: Tidak ada entri di cache-pins.nix", file=sys.stderr)
        sys.exit(1)

    pin_sources = load_pin_sources(pins_file)
    disk_cache = LocalDiskCache()

    mode_title = "[PERMANEN / WRITE MODE]" if write_to_file else "[DRY-RUN / PREVIEW MODE]"

    print("================================================================================", file=sys.stderr)
    print(f" Memeriksa pembaruan upstream untuk {len(pins_data)} paket {mode_title} ", file=sys.stderr)
    if explicit_input:
        print(f" Global Upstream Input : {nixpkgs_input} (Override mode)", file=sys.stderr)
    else:
        print(" Multi-Source Channel  : Otomatis mendeteksi atribut channel per pin", file=sys.stderr)
    if version_only:
        print(" Filter Kebijakan      : --version-only (Mengabaikan rebuild berversi sama)", file=sys.stderr)
    if refresh:
        print(" Cache Policy          : --refresh (Memaksa evaluasi ulang)", file=sys.stderr)
    print(f" Binary Cache Target   : {cache_client.summary_display}", file=sys.stderr)
    print("================================================================================", file=sys.stderr)

    # 1. Group targets by effective channel input
    channel_groups: Dict[str, Dict[str, Optional[str]]] = defaultdict(dict)

    for key, data in pins_data.items():
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

        channel_groups[effective_input][key] = pname

    # 2. Evaluate all channels using disk cache + single-pass batch evaluation
    all_evaluated: Dict[str, PackageMeta] = {}

    for chan_input, target_dict in channel_groups.items():
        hits, missing = disk_cache.get_batch(chan_input, list(target_dict.keys()), bypass_cache=refresh)
        all_evaluated.update(hits)

        if missing:
            chan_label = normalize_channel_name(chan_input)
            print(f"⚡ Batch Nix evaluation: {len(missing)} paket dari '{chan_label}'...", file=sys.stderr)
            missing_targets = {k: target_dict[k] for k in missing}
            new_evals = evaluate_batch(missing_targets, nixpkgs_input=chan_input)

            # Store to disk cache
            valid_new_evals = {k: m for k, m in new_evals.items() if m and m.store_path}
            if valid_new_evals:
                disk_cache.set_batch(chan_input, valid_new_evals)
                all_evaluated.update(valid_new_evals)

    # 3. Process results, check cache hits, and prepare updates
    auditor = ClosureAuditor(cache_client) if write_to_file else None
    updated_snippets: Dict[str, str] = {}
    updated_count, skipped_count, ready_count, uptodate_count = 0, 0, 0, 0

    for key in sorted(pins_data.keys()):
        data = pins_data[key]
        current_store_path = data.get("storePath", "")
        current_version = data.get("version", "unknown")
        declared_channel = data.get("channel")

        meta = all_evaluated.get(key)
        if not meta or not meta.store_path:
            print(f"  ⚠️  [{key}] Gagal evaluasi upstream.", file=sys.stderr)
            continue

        new_store_path = meta.store_path
        new_version = meta.version
        main_program = meta.main_program
        effective_input = meta.channel or declared_channel or nixpkgs_input

        if new_store_path == current_store_path:
            uptodate_count += 1
            print(f"  ✅ [{key}] Sudah versi terbaru (v{current_version}) [{declared_channel or normalize_channel_name(effective_input)}]", file=sys.stderr)
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
                    f"  ⏳ [{key}] Upstream ({normalize_channel_name(effective_input)}) v{new_version} < v{current_version} (mencegah downgrade). Dilewati.",
                    file=sys.stderr,
                )
                skipped_count += 1
                continue

        # Check binary cache HIT
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
            updated_snippets[key] = nix_snippet
            if is_rebuild:
                print(f"  🔄 [{key}] REBUILD DIPERBARUI: v{current_version} (hash: {old_hash[:7]} ➔ {new_hash[:7]}) [{declared_channel or normalize_channel_name(effective_input)}]", file=sys.stderr)
            else:
                print(f"  🚀 [{key}] VERSI DIPERBARUI: v{current_version} ➔ v{new_version} (hash: {old_hash[:7]} ➔ {new_hash[:7]}) [{declared_channel or normalize_channel_name(effective_input)}]", file=sys.stderr)
            updated_count += 1
        else:
            if is_rebuild:
                print(f"  🔄 [{key}] TERSEDIA REBUILD / HASH UPDATE: v{current_version} (hash: {old_hash[:7]} ➔ {new_hash[:7]}) [{declared_channel or normalize_channel_name(effective_input)}]", file=sys.stderr)
            else:
                print(f"  ✨ [{key}] TERSEDIA VERSI BARU: v{current_version} ➔ v{new_version} (hash: {old_hash[:7]} ➔ {new_hash[:7]}) [{declared_channel or normalize_channel_name(effective_input)}]", file=sys.stderr)
            ready_count += 1

    # 4. Atomic batch write if write mode is active
    if write_to_file and updated_snippets:
        write_or_update_pins_batch(pins_file, updated_snippets)

    print("--------------------------------------------------------------------------------", file=sys.stderr)
    if write_to_file:
        print(f"🎉 Selesai! {updated_count} paket berhasil disimpan secara atomik ke {pins_file.name}.", file=sys.stderr)
    else:
        print(f"📊 Ringkasan Dry-Run: {ready_count} pembaruan siap diterapkan, {uptodate_count} up-to-date, {skipped_count} dilewati.", file=sys.stderr)
        if ready_count > 0:
            print(f"💡 Untuk menyimpan pembaruan ke {pins_file.name}, jalankan kembali dengan flag '-w' / '--write':", file=sys.stderr)
            print("   ncp update --all -w", file=sys.stderr)


def _handle_update_system(args, cache_client: NixCacheClient) -> None:
    """Handle `ncp update system` workflow: update flake.lock and pre-fetch system closure via aria2."""
    import subprocess
    from core.eval.channels import find_flake_dir
    from downloader.orchestrator import download_system_targets

    flake_dir = find_flake_dir()
    if not flake_dir:
        print("❌ ERROR: Direktori flake (berisi flake.nix) tidak ditemukan.", file=sys.stderr)
        sys.exit(1)

    flake_input = getattr(args, "flake_input", None)
    if not flake_input and "--input" in sys.argv:
        # User passed --input explicitly on CLI
        flake_input = getattr(args, "input", None)

    print("================================================================================", file=sys.stderr)
    if flake_input:
        print(f"🔄 Memperbarui Flake Input: '{flake_input}' di {flake_dir}...", file=sys.stderr)
        cmd = ["nix", "flake", "update", flake_input]
    else:
        print(f"🔄 Memperbarui seluruh dependensi di flake.lock ({flake_dir})...", file=sys.stderr)
        cmd = ["nix", "flake", "update"]
    print("================================================================================", file=sys.stderr)

    res = subprocess.run(cmd, cwd=str(flake_dir))
    if res.returncode != 0:
        print(f"❌ ERROR: 'nix flake update' gagal dengan kode keluar {res.returncode}.", file=sys.stderr)
        sys.exit(res.returncode)

    print("\n✅ Pembaruan flake.lock selesai dengan sukses!", file=sys.stderr)
    print("🚀 Melanjutkan ke pre-fetching biner closure sistem via aria2c...\n", file=sys.stderr)

    download_system_targets(
        cache_client=cache_client,
        hostname=getattr(args, "host", None),
        cache_dir=getattr(args, "cache_dir", None),
        split=getattr(args, "split", 8),
        concurrent=getattr(args, "concurrent", 4),
        keep_nar=getattr(args, "keep_nar", False),
        verbose=getattr(args, "verbose", False),
        dry_run=getattr(args, "dry_run", False),
    )

