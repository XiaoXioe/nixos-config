#!/usr/bin/env python3
"""query-cache-pin — CLI for evaluating, updating, auditing, adopting, and managing Nix binary cache pins."""
import argparse
import concurrent.futures
import os
from pathlib import Path
import sys
from typing import Optional

_scripts_dir = str(Path(__file__).resolve().parent)
if _scripts_dir not in sys.path:
    sys.path.insert(0, _scripts_dir)

from core.cache_client import NixCacheClient
from core.closure import ClosureAuditor
from core.nix_eval import (
    compare_versions,
    eval_nix_raw,
    evaluate_upstream_package,
    extract_version_from_store_path,
    find_cache_pins_file,
    resolve_channel_input,
    resolve_target_to_store_path,
)
from downloader.orchestrator import download_batch_targets
from registry.adopt import adopt_module_pin, find_modules_referencing_pkg
from registry.audit import find_unused_pins
from registry.store import (
    delete_pin_entry,
    load_cache_pins,
    load_pin_sources,
    write_or_update_pin,
)
from ui.formatters import render_audit_report, render_nix_snippet
from ui.stats import render_stats_dashboard
from ui.tui import launch_cache_dashboard
from ui.version_picker import interactive_version_picker


def handle_all_mode(cache_client: NixCacheClient, pins_file_path: Optional[str] = None):
    """Verify hit/miss status for all store paths in cache-pins.nix."""
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
    if fail_count > 0:
        sys.exit(1)
    sys.exit(0)


def handle_update_single(
    target_key: str,
    cache_client: NixCacheClient,
    nixpkgs_input: str,
    pins_file_path: Optional[str] = None,
    force: bool = False,
    explicit_input: bool = False,
    write_to_file: bool = False,
    version_only: bool = False,
):
    """Check and update a single pin from upstream channel if binary cache HIT exists (Dry-run by default, write with -w)."""
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

    if explicit_input:
        effective_input = nixpkgs_input
    elif declared_channel:
        effective_input = resolve_channel_input(declared_channel)
    elif pin_sources.get(attr_key):
        effective_input = resolve_channel_input(pin_sources.get(attr_key))
    else:
        effective_input = nixpkgs_input

    print(f"🔍 Memeriksa pembaruan upstream untuk '{attr_key}' dari {effective_input}...", file=sys.stderr)

    new_store_path, new_version, main_program = evaluate_upstream_package(attr_key, effective_input)

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
        print(f"   Gunakan 'qcp --update {attr_key} -w' untuk menyimpan perubahan ke berkas.", file=sys.stderr)


def handle_update_all(
    cache_client: NixCacheClient,
    nixpkgs_input: str,
    pins_file_path: Optional[str] = None,
    force: bool = False,
    explicit_input: bool = False,
    write_to_file: bool = False,
    version_only: bool = False,
):
    """Check and update all pins from upstream channel in batch with source retention and downgrade guard."""
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
        print(f" Multi-Source Channel  : Otomatis mendeteksi atribut channel per pin", file=sys.stderr)
    if version_only:
        print(f" Filter Kebijakan      : --version-only (Mengabaikan rebuild berversi sama)", file=sys.stderr)
    print(f" Binary Cache Target   : {cache_client.summary_display}", file=sys.stderr)
    print("============================================================", file=sys.stderr)

    auditor = ClosureAuditor(cache_client)
    updated_count, skipped_count, ready_count = 0, 0, 0

    for key, data in sorted(pins_data.items()):
        current_store_path = data.get("storePath", "")
        current_version = data.get("version", "unknown")
        declared_channel = data.get("channel")

        if explicit_input:
            effective_input = nixpkgs_input
        elif declared_channel:
            effective_input = resolve_channel_input(declared_channel)
        elif pin_sources.get(key):
            effective_input = resolve_channel_input(pin_sources.get(key))
        else:
            effective_input = nixpkgs_input

        new_store_path, new_version, main_program = evaluate_upstream_package(key, effective_input)

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
        print(f"   qcp --update-all -w", file=sys.stderr)


def handle_audit_unused(pins_file_path: Optional[str] = None):
    """Audit cache-pins usage across NixOS codebase and report active vs dangling pins."""
    pins_file = find_cache_pins_file(pins_file_path)
    if not pins_file:
        print("❌ ERROR: Tidak dapat menemukan berkas modules/_lib/cache-pins.nix", file=sys.stderr)
        sys.exit(1)

    print("============================================================", file=sys.stderr)
    print(" Audit Penggunaan Cache Pins di Codebase Modul NixOS        ", file=sys.stderr)
    print("============================================================", file=sys.stderr)

    used, unused = find_unused_pins(pins_file)

    print("\n📦 PIN TERPAKAI (AKTIF):", file=sys.stderr)
    for key, refs in sorted(used.items()):
        ref_summary = ", ".join(refs[:2]) + (f" (+{len(refs)-2} lainnya)" if len(refs) > 2 else "")
        print(f"  ✅ {key:<22} ➔ {ref_summary}", file=sys.stderr)

    print(f"\nTotal Pin Aktif: {len(used)} paket", file=sys.stderr)

    if unused:
        print("\n⚠️  PIN TIDAK TERPAKAI / YATIM (DANGLING PINS):", file=sys.stderr)
        for key in sorted(unused):
            print(f"  ❌ {key:<22} (tidak ditemukan pemanggilan di modules/)", file=sys.stderr)
        print(f"\nTotal Pin Yatim: {len(unused)} paket", file=sys.stderr)
        print("Gunakan 'query-cache-pin --clean-unused' untuk membersihkan secara otomatis.", file=sys.stderr)
    else:
        print("\n✨ Sempurna! Semua entri di cache-pins.nix terpakai secara aktif di modul.", file=sys.stderr)
    sys.exit(0)


def handle_clean_unused(pins_file_path: Optional[str] = None, force: bool = False):
    """Delete all dangling pins from cache-pins.nix with interactive or forced confirmation."""
    pins_file = find_cache_pins_file(pins_file_path)
    if not pins_file:
        print("❌ ERROR: Tidak dapat menemukan berkas modules/_lib/cache-pins.nix", file=sys.stderr)
        sys.exit(1)

    _, unused = find_unused_pins(pins_file)
    if not unused:
        print("✨ Tidak ada pin yatim (dangling) yang perlu dibersihkan.", file=sys.stderr)
        sys.exit(0)

    print(f"Ditemukan {len(unused)} pin yatim: {', '.join(unused)}", file=sys.stderr)
    if not force:
        try:
            confirm = input("Apakah Anda yakin ingin menghapus pin-pin tersebut dari cache-pins.nix? [y/N]: ").strip().lower()
            if confirm not in ("y", "yes"):
                print("Operasi pembersihan dibatalkan.", file=sys.stderr)
                sys.exit(0)
        except EOFError:
            print("Operasi pembersihan dibatalkan (non-interactive).", file=sys.stderr)
            sys.exit(0)

    for key in unused:
        if delete_pin_entry(pins_file, key):
            print(f"  🗑️  Dihapus: {key}", file=sys.stderr)

    print(f"✨ Berhasil membersihkan {len(unused)} entri dari {pins_file.name}!", file=sys.stderr)
    sys.exit(0)


def handle_delete_single(target_key: str, pins_file_path: Optional[str] = None):
    """Delete a single pin entry from cache-pins.nix."""
    pins_file = find_cache_pins_file(pins_file_path)
    if not pins_file:
        print("❌ ERROR: Tidak dapat menemukan berkas modules/_lib/cache-pins.nix", file=sys.stderr)
        sys.exit(1)

    attr_key = target_key.replace("pkgs.", "")
    if delete_pin_entry(pins_file, attr_key):
        print(f"✨ Berhasil menghapus entri '{attr_key}' dari {pins_file.name}!", file=sys.stderr)
    else:
        print(f"❌ ERROR: Entri '{attr_key}' tidak ditemukan di {pins_file.name}", file=sys.stderr)
        sys.exit(1)
    sys.exit(0)


def handle_adopt(
    target_pkg: str,
    module_path_arg: Optional[str],
    cache_client: NixCacheClient,
    nixpkgs_input: str,
    pins_file_path: Optional[str] = None,
):
    """Adopt a package from pkgs into cache-pins and refactor consumer module files."""
    pins_file = find_cache_pins_file(pins_file_path)
    if not pins_file:
        print("❌ ERROR: Tidak dapat menemukan berkas modules/_lib/cache-pins.nix", file=sys.stderr)
        sys.exit(1)

    clean_attr = target_pkg.replace("pkgs.", "")

    target_modules: list[Path] = []
    if module_path_arg:
        p = Path(module_path_arg)
        if not p.is_file():
            print(f"❌ ERROR: Berkas modul target tidak ditemukan: {module_path_arg}", file=sys.stderr)
            sys.exit(1)
        target_modules.append(p.resolve())
    else:
        print(f"🔍 Mencari file modul yang mereferensikan 'pkgs.{clean_attr}'...", file=sys.stderr)
        target_modules = find_modules_referencing_pkg(clean_attr)
        if not target_modules:
            print(f"❌ ERROR: Tidak ditemukan modul yang memanggil 'pkgs.{clean_attr}'.", file=sys.stderr)
            print("   Harap tentukan path file modul secara eksplisit, contoh:", file=sys.stderr)
            print(f"   qcp --adopt {clean_attr} modules/path/to/module.nix", file=sys.stderr)
            sys.exit(1)

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


def main():
    """Main CLI entrypoint for query-cache-pin (qcp)."""
    parser = argparse.ArgumentParser(
        description="query-cache-pin — Generate & update entri cache-pins.nix dengan analisis mendalam, audit closure, & pencarian versi via FZF"
    )
    parser.add_argument(
        "target",
        nargs="?",
        help="Nama paket (pkgs.<attr> atau <attr>), Nix store path (/nix/store/...), atau key cache-pins",
    )
    parser.add_argument(
        "extra_target",
        nargs="?",
        help="Argumen target kedua (contoh: path file modul saat menggunakan --adopt)",
    )
    parser.add_argument(
        "-c",
        "--channel",
        help="Shorthand channel Nixpkgs (contoh: unstable, 26.05, 25.11, 25.05, 24.11, master)",
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="Menampilkan seluruh (100%%) daftar dependensi (baik lokal maupun remote)",
    )
    parser.add_argument(
        "-w",
        "--write",
        action="store_true",
        help="Otomatis menulis / memperbarui entri di modules/_lib/cache-pins.nix",
    )
    parser.add_argument(
        "-d",
        "--delete",
        metavar="KEY",
        help="Hapus entri paket tertentu dari modules/_lib/cache-pins.nix",
    )
    parser.add_argument(
        "--adopt",
        metavar="KEY",
        help="Adopsi paket dari pkgs.<key> ke cache pin dan otomatis refactor file modul target",
    )
    parser.add_argument(
        "--stats",
        "--summary",
        action="store_true",
        dest="stats",
        help="Tampilkan dashboard statistik, kesehatan pin, dan kesiapan /nix/store",
    )
    parser.add_argument(
        "--prefetch",
        action="store_true",
        help="Unduh seluruh closure pin yang aktif ke /nix/store via aria2c",
    )
    parser.add_argument(
        "-i",
        "--interactive",
        action="store_true",
        help="Buka TUI Dashboard interaktif berbasis fzf",
    )
    parser.add_argument(
        "-s",
        "--search-versions",
        action="store_true",
        help="Cari versi lain dari paket via FZF (NixHub & release channels)",
    )
    parser.add_argument(
        "--all",
        action="store_true",
        help="Evaluasi & verifikasi ketersediaan seluruh entri di modules/_lib/cache-pins.nix",
    )
    parser.add_argument(
        "--audit-unused",
        "--audit-orphan",
        action="store_true",
        dest="audit_unused",
        help="Audit penggunaan pin di codebase modules/ (mendeteksi dangling pins)",
    )
    parser.add_argument(
        "--clean-unused",
        "--clean-orphan",
        action="store_true",
        dest="clean_unused",
        help="Hapus seluruh pin yang tidak lagi terpakai dari cache-pins.nix",
    )
    parser.add_argument(
        "-f",
        "--force",
        action="store_true",
        help="Lewati konfirmasi interaktif saat membersihkan pin",
    )
    parser.add_argument(
        "--update",
        metavar="KEY",
        help="Periksa dan perbarui paket tertentu dari upstream jika biner cache tersedia",
    )
    parser.add_argument(
        "--update-all",
        action="store_true",
        help="Periksa dan perbarui seluruh entri cache-pins.nix dari upstream jika biner cache tersedia",
    )
    parser.add_argument(
        "--version-only",
        "--bump-only",
        action="store_true",
        dest="version_only",
        help="Hanya perbarui jika versi rilis upstream naik (mengabaikan rebuild jika versi sama)",
    )
    parser.add_argument(
        "--cache-url",
        default=None,
        help="Binary cache URL (dukungan multi-cache dipisahkan koma, default: auto-detect substituters sistem)",
    )
    parser.add_argument(
        "--input",
        default=os.environ.get("NIXPKGS_INPUT", "nixpkgs"),
        help="Flake input target (default: nixpkgs)",
    )
    parser.add_argument("--pins-file", help="Path eksplisit ke berkas cache-pins.nix")

    args = parser.parse_args()

    # Handle channel shorthand
    if args.channel:
        args.input = resolve_channel_input(args.channel)

    if args.stats:
        pins_file = find_cache_pins_file(args.pins_file)
        if not pins_file:
            print("❌ ERROR: Tidak dapat menemukan berkas modules/_lib/cache-pins.nix", file=sys.stderr)
            sys.exit(1)
        render_stats_dashboard(pins_file)
        sys.exit(0)

    if args.prefetch:
        cache_client = NixCacheClient(cache_url=args.cache_url)
        download_batch_targets(
            all_pins=False,
            cache_client=cache_client,
            pins_file_path=args.pins_file,
        )
        sys.exit(0)

    if args.adopt:
        cache_client = NixCacheClient(cache_url=args.cache_url)
        mod_arg = args.target if args.target and (args.target.endswith(".nix") or "/" in args.target) else args.extra_target
        handle_adopt(args.adopt, mod_arg, cache_client, args.input, args.pins_file)

    if args.audit_unused:
        handle_audit_unused(args.pins_file)

    if args.clean_unused:
        handle_clean_unused(args.pins_file, force=args.force)

    if args.delete:
        handle_delete_single(args.delete, args.pins_file)

    if args.interactive:
        launch_cache_dashboard(
            pins_file_path=args.pins_file,
            cache_url=args.cache_url,
            nixpkgs_input=args.input,
        )
        sys.exit(0)

    target_input = args.target

    if args.search_versions:
        if not target_input:
            target_input = input("Masukkan nama paket yang ingin dicari versinya: ").strip()
            if not target_input:
                sys.exit(0)
        selected_version = interactive_version_picker(target_input, cache_url=args.cache_url)
        if not selected_version:
            print("Pencarian versi dibatalkan.", file=sys.stderr)
            sys.exit(0)
        args.input = selected_version["flake_input"]
        target_input = selected_version["attr"]
        print(f"🎯 Versi terpilih: v{selected_version['version']} ({args.input})", file=sys.stderr)

    cache_client = NixCacheClient(cache_url=args.cache_url)

    explicit_input = bool(args.channel) or ("--input" in sys.argv) or ("-c" in sys.argv) or ("--channel" in sys.argv)

    if args.all:
        handle_all_mode(cache_client, args.pins_file)

    if args.update_all:
        handle_update_all(
            cache_client,
            args.input,
            args.pins_file,
            force=args.force,
            explicit_input=explicit_input,
            write_to_file=args.write,
            version_only=args.version_only,
        )
        sys.exit(0)

    if args.update:
        handle_update_single(
            args.update,
            cache_client,
            args.input,
            args.pins_file,
            force=args.force,
            explicit_input=explicit_input,
            write_to_file=args.write,
            version_only=args.version_only,
        )
        sys.exit(0)

    if not target_input:
        parser.print_help(file=sys.stderr)
        sys.exit(1)

    pins_file = find_cache_pins_file(args.pins_file)

    print(f"🔍 [1/3] Mengevaluasi target '{target_input}' (Channel: {args.input})...", file=sys.stderr)
    try:
        store_path, version, main_program = resolve_target_to_store_path(
            target=target_input,
            nixpkgs_input=args.input,
            pins_file=pins_file,
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
            target_name=target_input,
            store_path=store_path,
            version=version,
            main_program=main_program,
        )
    except Exception as e:
        print(f"❌ ERROR: {e}", file=sys.stderr)
        sys.exit(1)

    print("🔬 [3/3] Menyusun laporan analisis dan template Nix...", file=sys.stderr)
    report_text = render_audit_report(audit, verbose=args.verbose)
    print(report_text, file=sys.stderr)

    nix_snippet = render_nix_snippet(audit, source_input=args.input)
    print(nix_snippet)

    if args.write:
        if not pins_file:
            print("❌ ERROR: Tidak dapat menemukan cache-pins.nix untuk ditulis.", file=sys.stderr)
            sys.exit(1)
        attr_key = target_input.replace("pkgs.", "")
        write_or_update_pin(pins_file, attr_key, nix_snippet)
        print(f"✨ Berhasil menulis entri '{attr_key}' ke {pins_file.name}!", file=sys.stderr)


if __name__ == "__main__":
    main()
