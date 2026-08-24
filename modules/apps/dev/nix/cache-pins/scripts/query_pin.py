#!/usr/bin/env python3
"""query-cache-pin — Generate & update entri cache-pins.nix dengan analisis mendalam, audit closure, & pencarian versi via FZF."""
import argparse
import concurrent.futures
import os
from pathlib import Path
import sys
from typing import Optional

_scripts_dir = str(Path(__file__).resolve().parent)
if _scripts_dir not in sys.path:
    sys.path.insert(0, _scripts_dir)

from cache_client import NixCacheClient
from formatters import render_audit_report, render_nix_snippet
from nix_utils import (
    eval_nix_raw,
    find_cache_pins_file,
    load_cache_pins,
    resolve_channel_input,
    resolve_target_to_store_path,
    write_or_update_pin,
)
from tui import launch_cache_dashboard
from version_search import interactive_version_picker


def handle_all_mode(cache_client: NixCacheClient, pins_file_path: Optional[str] = None):
    pins_file = find_cache_pins_file(pins_file_path)
    if not pins_file:
        print(
            "❌ ERROR: Tidak dapat menemukan berkas modules/_lib/cache-pins.nix",
            file=sys.stderr,
        )
        sys.exit(1)

    print("============================================================", file=sys.stderr)
    print(" Memverifikasi seluruh entri di modules/_lib/cache-pins.nix ", file=sys.stderr)
    print(f" Cache Target: {cache_client.cache_url}", file=sys.stderr)
    print("============================================================", file=sys.stderr)

    pins_data = load_cache_pins(pins_file)
    if not pins_data:
        print("❌ ERROR: Tidak ada entri valid ditemukan di cache-pins.nix", file=sys.stderr)
        sys.exit(1)

    items = []
    for name, data in pins_data.items():
        if isinstance(data, dict) and "storePath" in data:
            items.append((name, data["storePath"]))

    ok_count = 0
    fail_count = 0

    def check_entry(item):
        name, store_path = item
        h = os.path.basename(store_path).split("-")[0]
        hit = cache_client.check_hit(h)
        return name, store_path, hit

    with concurrent.futures.ThreadPoolExecutor(max_workers=cache_client.max_workers) as executor:
        results = list(executor.map(check_entry, items))

    for name, store_path, hit in results:
        if hit:
            print(f"  ✅ [HIT]  {name}: {store_path}", file=sys.stderr)
            ok_count += 1
        else:
            print(f"  ❌ [MISS] {name}: {store_path} — TIDAK DITEMUKAN", file=sys.stderr)
            fail_count += 1

    print("", file=sys.stderr)
    print(f"Status Cache: {ok_count} Tersedia, {fail_count} Tidak Ditemukan", file=sys.stderr)
    if fail_count > 0:
        sys.exit(1)
    sys.exit(0)


def handle_update_single(
    target_key: str,
    cache_client: NixCacheClient,
    nixpkgs_input: str,
    pins_file_path: Optional[str] = None,
):
    pins_file = find_cache_pins_file(pins_file_path)
    if not pins_file:
        print("❌ ERROR: Tidak dapat menemukan modules/_lib/cache-pins.nix", file=sys.stderr)
        sys.exit(1)

    attr_key = target_key.replace("pkgs.", "")
    print(f"🔍 Memeriksa pembaruan upstream untuk '{attr_key}' dari {nixpkgs_input}...", file=sys.stderr)

    eval_target = f"pkgs.{attr_key}.outPath"
    new_store_path = eval_nix_raw(eval_target, nixpkgs_input) or eval_nix_raw(f"{attr_key}.outPath", nixpkgs_input)

    if not new_store_path or not new_store_path.startswith("/nix/store/"):
        print(f"❌ ERROR: Gagal mengevaluasi outPath upstream untuk '{attr_key}'", file=sys.stderr)
        sys.exit(1)

    new_hash = os.path.basename(new_store_path).split("-")[0]
    if not cache_client.check_hit(new_hash):
        print(f"⚠️  Pemberitahuan: Biner upstream untuk {new_store_path} belum tersedia di binary cache (MISS).", file=sys.stderr)
        print("   Pin lama dipertahankan agar tidak terjadi kompilasi lokal.", file=sys.stderr)
        sys.exit(1)

    main_program = eval_nix_raw(f"pkgs.{attr_key}.meta.mainProgram", nixpkgs_input) or eval_nix_raw(
        f"{attr_key}.meta.mainProgram", nixpkgs_input
    )
    from nix_utils import extract_version_from_store_path

    version = extract_version_from_store_path(new_store_path)

    audit = cache_client.audit_closure(
        target_name=attr_key,
        store_path=new_store_path,
        version=version,
        main_program=main_program,
    )

    report_text = render_audit_report(audit, verbose=False)
    print(report_text, file=sys.stderr)

    nix_snippet = render_nix_snippet(audit, source_input=nixpkgs_input)
    write_or_update_pin(pins_file, attr_key, nix_snippet)
    print(f"✨ Berhasil memperbarui entri '{attr_key}' di {pins_file.name}!", file=sys.stderr)


def handle_update_all(
    cache_client: NixCacheClient,
    nixpkgs_input: str,
    pins_file_path: Optional[str] = None,
):
    pins_file = find_cache_pins_file(pins_file_path)
    if not pins_file:
        print("❌ ERROR: Tidak dapat menemukan modules/_lib/cache-pins.nix", file=sys.stderr)
        sys.exit(1)

    pins_data = load_cache_pins(pins_file)
    if not pins_data:
        print("❌ ERROR: Tidak ada entri di cache-pins.nix", file=sys.stderr)
        sys.exit(1)

    print("============================================================", file=sys.stderr)
    print(f" Memeriksa pembaruan upstream untuk {len(pins_data)} paket... ", file=sys.stderr)
    print(f" Upstream Input: {nixpkgs_input} | Cache: {cache_client.cache_url}", file=sys.stderr)
    print("============================================================", file=sys.stderr)

    from nix_utils import extract_version_from_store_path

    updated_count = 0
    skipped_count = 0

    for key, data in sorted(pins_data.items()):
        current_store_path = data.get("storePath", "")
        current_version = data.get("version", "unknown")

        eval_target = f"pkgs.{key}.outPath"
        new_store_path = eval_nix_raw(eval_target, nixpkgs_input) or eval_nix_raw(f"{key}.outPath", nixpkgs_input)

        if not new_store_path or not new_store_path.startswith("/nix/store/"):
            print(f"  ⚠️  [{key}] Gagal evaluasi upstream.", file=sys.stderr)
            continue

        if new_store_path == current_store_path:
            print(f"  ✅ [{key}] Sudah versi terbaru (v{current_version})", file=sys.stderr)
            continue

        new_hash = os.path.basename(new_store_path).split("-")[0]
        new_version = extract_version_from_store_path(new_store_path)

        if not cache_client.check_hit(new_hash):
            print(f"  ⏳ [{key}] Upstream baru ada (v{new_version}), tapi belum ready di binary cache (MISS). Dilewati.", file=sys.stderr)
            skipped_count += 1
            continue

        main_program = eval_nix_raw(f"pkgs.{key}.meta.mainProgram", nixpkgs_input) or eval_nix_raw(
            f"{key}.meta.mainProgram", nixpkgs_input
        )

        audit = cache_client.audit_closure(
            target_name=key,
            store_path=new_store_path,
            version=new_version,
            main_program=main_program,
        )

        nix_snippet = render_nix_snippet(audit, source_input=nixpkgs_input)
        write_or_update_pin(pins_file, key, nix_snippet)
        print(f"  🚀 [{key}] DIPERBARUI: v{current_version} ➔ v{new_version}", file=sys.stderr)
        updated_count += 1

    print("", file=sys.stderr)
    print(f"Selesai! {updated_count} paket diperbarui, {skipped_count} paket dilewati.", file=sys.stderr)


def main():
    parser = argparse.ArgumentParser(
        description="query-cache-pin — Generate & update entri cache-pins.nix dengan analisis mendalam, audit closure, & pencarian versi via FZF"
    )
    parser.add_argument(
        "target",
        nargs="?",
        help="Nama paket (pkgs.<attr> atau <attr>), Nix store path (/nix/store/...), atau key cache-pins",
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
        "--cache-url",
        default=os.environ.get("CACHE_URL", "https://cache.nixos.org"),
        help="Binary cache URL (dukungan multi-cache dipisahkan koma)",
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
        selected_version = interactive_version_picker(target_input)
        if not selected_version:
            print("Pencarian versi dibatalkan.", file=sys.stderr)
            sys.exit(0)
        args.input = selected_version["flake_input"]
        target_input = selected_version["attr"]
        print(f"🎯 Versi terpilih: v{selected_version['version']} ({args.input})", file=sys.stderr)

    cache_client = NixCacheClient(cache_url=args.cache_url)

    if args.all:
        handle_all_mode(cache_client, args.pins_file)

    if args.update_all:
        handle_update_all(cache_client, args.input, args.pins_file)
        sys.exit(0)

    if args.update:
        handle_update_single(args.update, cache_client, args.input, args.pins_file)
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
        f"🌐 [2/3] Mengambil metadata & pohon dependensi dari {cache_client.cache_url}...",
        file=sys.stderr,
    )
    try:
        audit = cache_client.audit_closure(
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
