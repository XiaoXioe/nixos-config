"""ncp delete — Remove a pin entry from cache-pins.nix."""
import sys


def handle_delete(args) -> None:
    """Handle the `ncp delete` subcommand."""
    from core.nix_eval import find_cache_pins_file
    from registry.store import delete_pin_entry

    if not args.target:
        print("❌ ERROR: Tentukan nama pin yang ingin dihapus. Contoh: ncp delete aria2", file=sys.stderr)
        sys.exit(1)

    pins_file = find_cache_pins_file(args.pins_file)
    if not pins_file:
        print("❌ ERROR: Tidak dapat menemukan berkas modules/_lib/cache-pins.nix", file=sys.stderr)
        sys.exit(1)

    attr_key = args.target.replace("pkgs.", "")
    if delete_pin_entry(pins_file, attr_key):
        print(f"✨ Berhasil menghapus entri '{attr_key}' dari {pins_file.name}!", file=sys.stderr)
    else:
        print(f"❌ ERROR: Entri '{attr_key}' tidak ditemukan di {pins_file.name}", file=sys.stderr)
        sys.exit(1)
    sys.exit(0)
