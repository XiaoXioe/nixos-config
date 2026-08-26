"""ncp diff — Compare closure differences between pinned and upstream package versions."""
import os
from pathlib import Path
import subprocess
import sys
from typing import Optional


def handle_diff(args) -> None:
    """Handle the `ncp diff` subcommand."""
    if not args.target:
        print("❌ ERROR: Tentukan nama paket yang ingin dibandingkan. Contoh: ncp diff aria2", file=sys.stderr)
        sys.exit(1)

    from core.nix_eval import (
        evaluate_upstream_package,
        find_cache_pins_file,
        resolve_channel_input,
    )
    from registry.store import load_cache_pins, load_pin_sources

    pins_file = find_cache_pins_file(args.pins_file)
    if not pins_file:
        print("❌ ERROR: Tidak dapat menemukan berkas modules/_lib/cache-pins.nix", file=sys.stderr)
        sys.exit(1)

    clean_key = args.target.replace("pkgs.", "")
    pins_data = load_cache_pins(pins_file)
    pin_sources = load_pin_sources(pins_file)

    current_data = pins_data.get(clean_key, {})
    current_store_path = current_data.get("storePath", "")
    current_version = current_data.get("version", "unknown")
    declared_channel = current_data.get("channel")

    if not current_store_path:
        print(f"❌ ERROR: Pin untuk '{clean_key}' tidak ditemukan di {pins_file.name}.", file=sys.stderr)
        print(f"   Gunakan 'ncp query {clean_key} -w' untuk mendaftarkannya terlebih dahulu.", file=sys.stderr)
        sys.exit(1)

    # Determine upstream input
    explicit_input = bool(getattr(args, "channel", None)) or ("--input" in sys.argv)
    if explicit_input:
        effective_input = args.input
    elif declared_channel:
        effective_input = resolve_channel_input(declared_channel)
    elif pin_sources.get(clean_key):
        effective_input = resolve_channel_input(pin_sources.get(clean_key))
    else:
        effective_input = args.input if args.input else "nixpkgs"

    pname = current_data.get("pname")

    print(f"🔍 [1/2] Mengevaluasi store path upstream untuk '{clean_key}' dari {effective_input}...", file=sys.stderr)
    upstream_store_path, upstream_version, _ = evaluate_upstream_package(clean_key, effective_input, pname=pname)

    if not upstream_store_path or not upstream_store_path.startswith("/nix/store/"):
        print(f"❌ ERROR: Gagal mengevaluasi versi upstream untuk '{clean_key}' dari {effective_input}.", file=sys.stderr)
        sys.exit(1)

    print("📊 [2/2] Membandingkan closure dependensi...", file=sys.stderr)
    print("================================================================================", file=sys.stderr)
    print(f"📦 Paket Target   : {clean_key}", file=sys.stderr)
    print(f"📌 Pin Lokal      : {current_store_path} (v{current_version})", file=sys.stderr)
    print(f"🌐 Upstream Target: {upstream_store_path} (v{upstream_version}) [{effective_input}]", file=sys.stderr)
    print("================================================================================", file=sys.stderr)

    if current_store_path == upstream_store_path:
        print("✅ Status: Pin lokal dan upstream 100% identik (tidak ada perbedaan closure).", file=sys.stderr)
        sys.exit(0)

    use_deep = getattr(args, "deep", False)

    if use_deep:
        # Use nix-diff for semantic AST derivation comparison
        try:
            cmd = ["nix-diff", current_store_path, upstream_store_path]
            res = subprocess.run(cmd, text=True)
            sys.exit(res.returncode)
        except FileNotFoundError:
            print("⚠️  Tool 'nix-diff' belum terpasang di PATH.", file=sys.stderr)
            print("   Jalankan 'nix shell nixpkgs#nix-diff --command ncp diff ... --deep' atau switch sistem.", file=sys.stderr)

    # Default: Use nvd for package version diffing
    try:
        cmd = ["nvd", "diff", current_store_path, upstream_store_path]
        res = subprocess.run(cmd, text=True)
        if res.returncode == 0:
            sys.exit(0)
    except FileNotFoundError:
        pass

    # Fallback to direct text summary if nvd is not yet installed in current PATH
    print("\n⚠️  Catatan: 'nvd' tidak ditemukan di PATH (akan aktif setelah 'nh os switch').", file=sys.stderr)
    print("📋 Ringkasan Perbedaan:", file=sys.stderr)
    old_h = os.path.basename(current_store_path).split("-")[0]
    new_h = os.path.basename(upstream_store_path).split("-")[0]
    if current_version == upstream_version:
        print(f"  🔄 REBUILD HASH: Versi tetap (v{current_version}), hash berubah ({old_h[:7]} ➔ {new_h[:7]}).", file=sys.stderr)
        print("     (Kemungkinan terdapat update pada library dependensi C/Glibc di upstream)", file=sys.stderr)
    else:
        print(f"  🚀 VERSION BUMP: Versi naik dari v{current_version} ➔ v{upstream_version} ({old_h[:7]} ➔ {new_h[:7]}).", file=sys.stderr)
