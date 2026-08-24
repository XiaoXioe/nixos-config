"""Statistics and disk footprint analytics dashboard renderer for CLI."""
from pathlib import Path
import sys

from core.nix_eval import find_flake_dir, is_path_in_nix_store
from registry.audit import find_unused_pins
from registry.store import load_cache_pins


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

    print("================================================================================", file=sys.stderr)
    print("                 STATISTIK & FOOTPRINT CACHE PINS                              ", file=sys.stderr)
    print("================================================================================", file=sys.stderr)
    print(f"📁 Berkas Registry : {rel_pins}", file=sys.stderr)
    print(f"📦 Total Entri Pin : {total_pins} paket", file=sys.stderr)
    if total_pins > 0:
        print(f"  • Pin Aktif      : {active_count} paket ({active_count / total_pins * 100:.1f}%)", file=sys.stderr)
        print(f"  • Pin Yatim      : {unused_count} paket ({unused_count / total_pins * 100:.1f}%)", file=sys.stderr)
    print("--------------------------------------------------------------------------------", file=sys.stderr)
    hdr_p, hdr_v, hdr_s, hdr_l, hdr_m = "PAKET", "VERSI", "STATUS", "LOKAL STORE", "MODUL REF"
    print(f"{hdr_p:<22} {hdr_v:<14} {hdr_s:<12} {hdr_l:<14} {hdr_m}", file=sys.stderr)
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
        else:
            local_str = "⬇️  Missing"

        refs = used.get(key, [])
        if len(refs) > 1:
            ref_display = f"{len(refs)} modul"
        elif len(refs) == 1:
            ref_display = refs[0].split("/")[-1]
        else:
            ref_display = "-"

        print(f"{key:<22} {ver:<14} {status_str:<12} {local_str:<14} {ref_display}", file=sys.stderr)

    print("--------------------------------------------------------------------------------", file=sys.stderr)
    if total_pins > 0:
        print(
            f"📊 Kesiapan /nix/store: {local_hits}/{total_pins} ({local_hits / total_pins * 100:.1f}%) paket sudah tersimpan di disk lokal.",
            file=sys.stderr,
        )
    print("================================================================================", file=sys.stderr)
