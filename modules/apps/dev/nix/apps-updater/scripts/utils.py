import re
import subprocess
import urllib.request
import sys
from pathlib import Path

CONFIG_FILE = Path("modules/_lib/apps-versions.nix")

def natural_sort_key(s):
    """Helper untuk sorting versi secara alami (natural numeric sort)."""
    return [int(c) if c.isdigit() else c.lower() for c in re.split(r'(\d+)', str(s))]

def run_cmd(cmd):
    """Menjalankan perintah shell dan mengembalikan (stdout, returncode)."""
    res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    return res.stdout.strip(), res.returncode

def url_exists(url):
    """Memeriksa apakah URL unduhan aset rilis benar-benar ada (status 200/302)."""
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=5) as response:
            return response.status in (200, 302)
    except Exception:
        return False

def get_config_path():
    """Mencari path file apps-versions.nix dari direktori aktif atau git root."""
    if CONFIG_FILE.exists():
        return CONFIG_FILE
    git_root, code = run_cmd("git rev-parse --show-toplevel")
    if code == 0 and git_root:
        candidate = Path(git_root) / "modules/_lib/apps-versions.nix"
        if candidate.exists():
            return candidate
    print(f"Error: {CONFIG_FILE} tidak ditemukan. Pastikan dijalankan dari root repositori.")
    sys.exit(1)
