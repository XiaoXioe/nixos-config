"""ncp audit — Audit cache-pins usage across NixOS codebase and clean orphan pins."""
from pathlib import Path
import sys
from typing import Optional


def handle_audit(args) -> None:
    """Handle the `ncp audit` subcommand."""
    clean = getattr(args, "clean", False)
    force = getattr(args, "force", False)

    if clean:
        _handle_clean_unused(args.pins_file, force=force)
    else:
        _handle_audit_unused(args.pins_file)


def _handle_audit_unused(pins_file_path: Optional[str] = None) -> None:
    """Audit cache-pins usage across NixOS codebase and report active vs dangling pins."""
    from core.nix_eval import find_cache_pins_file
    from registry.audit import find_unused_pins

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
        print("Gunakan 'ncp audit --clean' untuk membersihkan secara otomatis.", file=sys.stderr)
    else:
        print("\n✨ Sempurna! Semua entri di cache-pins.nix terpakai secara aktif di modul.", file=sys.stderr)
    sys.exit(0)


def _handle_clean_unused(pins_file_path: Optional[str] = None, force: bool = False) -> None:
    """Delete all dangling pins from cache-pins.nix with interactive or forced confirmation."""
    from core.nix_eval import find_cache_pins_file
    from registry.audit import find_unused_pins
    from registry.store import delete_pin_entry

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
