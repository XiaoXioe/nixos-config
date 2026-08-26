"""Statistics and disk footprint analytics dashboard renderer for CLI."""
from pathlib import Path
import sys

from core.closure import get_local_closure_sizes_batch, get_local_unique_footprint
from core.eval.channels import find_flake_dir
from core.eval.resolver import is_path_in_nix_store
from registry.audit import find_unused_pins
from registry.store import load_cache_pins
from ui.formatters import format_bytes


def render_stats_dashboard(pins_file: Path):
    """Render comprehensive cache-pins health, store readiness, and module consumer stats."""
    pins_data = load_cache_pins(pins_file)
    used, unused = find_unused_pins(pins_file)

    flake_dir = find_flake_dir()
    rel_pins = (
        str(pins_file.relative_to(flake_dir))
        if flake_dir and flake_dir in pins_file.parents
        else str(pins_file)
    )

    total_pins = len(pins_data)
    active_count = len(used)
    unused_count = len(unused)

    all_store_paths = [
        data["storePath"]
        for data in pins_data.values()
        if isinstance(data, dict) and "storePath" in data and data["storePath"]
    ]

    closure_sizes = get_local_closure_sizes_batch(all_store_paths)
    dedup_bytes, unique_paths, cumulative_bytes = get_local_unique_footprint(all_store_paths)

    print("================================================================================", file=sys.stderr)
    print("                 STATISTIK & FOOTPRINT CACHE PINS                              ", file=sys.stderr)
    print("================================================================================", file=sys.stderr)
    print(f"📁 Berkas Registry : {rel_pins}", file=sys.stderr)
    print(f"📦 Total Entri Pin : {total_pins} paket", file=sys.stderr)
    if total_pins > 0:
        print(f"  • Pin Aktif      : {active_count} paket ({active_count / total_pins * 100:.1f}%)", file=sys.stderr)
        print(f"  • Pin Yatim      : {unused_count} paket ({unused_count / total_pins * 100:.1f}%)", file=sys.stderr)
    print("--------------------------------------------------------------------------------", file=sys.stderr)
    hdr_p, hdr_v, hdr_s, hdr_c, hdr_l, hdr_m = "PAKET", "VERSI", "STATUS", "UKURAN CLOSURE", "LOKAL STORE", "MODUL REF"
    print(f"{hdr_p:<20} {hdr_v:<14} {hdr_s:<10} {hdr_c:<15} {hdr_l:<14} {hdr_m}", file=sys.stderr)
    print("--------------------------------------------------------------------------------", file=sys.stderr)

    local_hits = 0
    for key, data in sorted(pins_data.items()):
        sp = data.get("storePath", "")
        ver = data.get("version", "-")
        is_active = key in used
        status_str = "✅ Aktif" if is_active else "⚠️  Yatim"

        is_local = is_path_in_nix_store(sp)
        if is_local:
            local_hits += 1
            local_str = "✅ Ada (0 B)"
            c_size = closure_sizes.get(sp, 0)
            c_size_str = format_bytes(c_size) if c_size > 0 else "-"
        else:
            local_str = "⬇️  Missing"
            c_size_str = "⬇️  Unknown"

        refs = used.get(key, [])
        if len(refs) > 1:
            ref_display = f"{len(refs)} modul"
        elif len(refs) == 1:
            ref_display = refs[0].split("/")[-1]
        else:
            ref_display = "-"

        print(f"{key:<20} {ver:<14} {status_str:<10} {c_size_str:<15} {local_str:<14} {ref_display}", file=sys.stderr)

    print("--------------------------------------------------------------------------------", file=sys.stderr)
    if total_pins > 0:
        print(
            f"📊 Kesiapan /nix/store      : {local_hits}/{total_pins} ({local_hits / total_pins * 100:.1f}%) paket tersimpan di disk lokal.",
            file=sys.stderr,
        )
        if cumulative_bytes > 0:
            print(f"📦 Total Akumulasi Closure   : {format_bytes(cumulative_bytes)} (Jumlah closure individual)", file=sys.stderr)
        if dedup_bytes > 0:
            saved_disk = max(0, cumulative_bytes - dedup_bytes)
            saved_pct = (saved_disk / cumulative_bytes * 100) if cumulative_bytes > 0 else 0
            print(f"💾 Total Footprint Riil Disk : {format_bytes(dedup_bytes)} ({unique_paths} unique store paths)", file=sys.stderr)
            print(f"⚡ Penghematan Shared Library : {format_bytes(saved_disk)} ({saved_pct:.1f}% dihemat berkat shared glibc/libs)", file=sys.stderr)
    print("================================================================================", file=sys.stderr)
