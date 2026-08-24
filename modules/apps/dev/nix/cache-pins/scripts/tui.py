"""Interactive FZF TUI Dashboard for inspecting and batch-downloading cache pins."""
import os
from pathlib import Path
import subprocess
import sys
from typing import List, Optional

_scripts_dir = str(Path(__file__).resolve().parent)
if _scripts_dir not in sys.path:
    sys.path.insert(0, _scripts_dir)

from cache_client import NixCacheClient
from nix_utils import find_cache_pins_file, is_path_in_nix_store, load_cache_pins


def launch_cache_dashboard(
    pins_file_path: Optional[str] = None,
    cache_url: str = "https://cache.nixos.org",
    nixpkgs_input: str = "nixpkgs",
) -> None:
    """Launch the interactive FZF dashboard."""
    pins_file = find_cache_pins_file(pins_file_path)
    if not pins_file:
        print("❌ ERROR: Tidak dapat menemukan berkas modules/_lib/cache-pins.nix", file=sys.stderr)
        sys.exit(1)

    which_fzf = subprocess.run(["which", "fzf"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    if which_fzf.returncode != 0:
        print("❌ ERROR: 'fzf' tidak ditemukan di sistem Anda.", file=sys.stderr)
        sys.exit(1)

    pins_data = load_cache_pins(pins_file)
    if not pins_data:
        print("❌ ERROR: Tidak ada entri valid ditemukan di cache-pins.nix", file=sys.stderr)
        sys.exit(1)

    # Build lines for fzf
    rows: List[str] = []
    for key, data in sorted(pins_data.items()):
        if not isinstance(data, dict):
            continue
        store_path = data.get("storePath", "")
        version = data.get("version", "unknown")
        is_local = is_path_in_nix_store(store_path)
        status_tag = "✅ Di Store  " if is_local else "⬇️  Belum Ada"

        # Format: key \t status \t version \t storePath
        row = f"{key:<20}  [{status_tag}]  v{version:<12}  {store_path}"
        rows.append(row)

    input_text = "\n".join(rows)

    query_script = str(Path(_scripts_dir) / "query_pin.py")
    preview_cmd = f"python3 {query_script} {{1}}"

    fzf_cmd = [
        "fzf",
        "--multi",
        "--ansi",
        "--prompt=📦 Nix Binary Cache Pins > ",
        "--header=Navigasi: ↑↓ | Pilih/Download: ENTER | Multi-select: TAB | Batal: Esc/Ctrl-C",
        f"--preview={preview_cmd}",
        "--preview-window=right:55%:wrap",
        "--layout=reverse",
        "--height=85%",
        "--border",
    ]

    try:
        proc = subprocess.run(fzf_cmd, input=input_text, text=True, capture_output=True)
    except KeyboardInterrupt:
        sys.exit(0)

    if proc.returncode != 0 or not proc.stdout.strip():
        print("Operasi dibatalkan.", file=sys.stderr)
        sys.exit(0)

    selected_lines = [line.strip() for line in proc.stdout.strip().splitlines() if line.strip()]
    selected_keys = [line.split()[0] for line in selected_lines]

    if not selected_keys:
        sys.exit(0)

    print(f"\n🚀 Memulai pengunduhan / ingest untuk {len(selected_keys)} paket terpilih:", file=sys.stderr)
    for k in selected_keys:
        print(f"  • {k}", file=sys.stderr)
    print("--------------------------------------------------------------------------------", file=sys.stderr)

    aria2_script = str(Path(_scripts_dir) / "aria2_fetch.py")
    for key in selected_keys:
        cmd = ["python3", aria2_script, key, f"--cache-url={cache_url}"]
        if nixpkgs_input:
            cmd.append(f"--input={nixpkgs_input}")
        subprocess.run(cmd)


if __name__ == "__main__":
    launch_cache_dashboard()
