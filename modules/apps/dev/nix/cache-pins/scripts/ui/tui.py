"""Interactive FZF TUI Dashboard for inspecting and batch-downloading cache pins."""
from pathlib import Path
import subprocess
import sys
from typing import List, Optional

from core.cache_client import NixCacheClient
from core.nix_eval import find_cache_pins_file, is_path_in_nix_store
from registry.store import load_cache_pins


def launch_cache_dashboard(
    pins_file_path: Optional[str] = None,
    cache_url: Optional[str] = None,
    nixpkgs_input: str = "nixpkgs",
) -> None:
    """Launch the interactive FZF dashboard for browsing cache pins and downloading."""
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

    # Build rows for fzf
    rows: List[str] = []
    for key, data in sorted(pins_data.items()):
        if not isinstance(data, dict):
            continue
        store_path = data.get("storePath", "")
        version = data.get("version", "unknown")
        is_local = is_path_in_nix_store(store_path)
        status_tag = "✅ Di Store  " if is_local else "⬇️  Belum Ada"

        row = f"{key:<20}  [{status_tag}]  v{version:<12}  {store_path}"
        rows.append(row)

    input_text = "\n".join(rows)

    scripts_dir = Path(__file__).resolve().parent.parent
    query_script = str(scripts_dir / "query_pin.py")
    cache_flag = f" --cache-url='{cache_url}'" if cache_url else ""
    preview_cmd = f"python3 {query_script} {{1}}{cache_flag}"

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

    aria2_script = str(scripts_dir / "aria2_fetch.py")
    for key in selected_keys:
        cmd = ["python3", aria2_script, key]
        if cache_url:
            cmd.append(f"--cache-url={cache_url}")
        if nixpkgs_input:
            cmd.append(f"--input={nixpkgs_input}")
        subprocess.run(cmd)
