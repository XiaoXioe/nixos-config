import json
from utils import run_cmd

def compute_sri_hash(url):
    """Mengunduh biner dan menghitung sha256 SRI hash (sha256-...)."""
    print(f"  ⬇️  Mengunduh & menghitung hash untuk: {url}")
    # Prioritas 1: Gunakan nix store prefetch-file --json
    out, code = run_cmd(f"nix store prefetch-file --json '{url}'")
    if code == 0 and out:
        try:
            data = json.loads(out)
            if "hash" in data:
                return data["hash"].strip()
        except Exception:
            pass

    # Prioritas 2: Fallback ke nix-prefetch-url + nix hash convert
    out, code = run_cmd(f"nix-prefetch-url '{url}'")
    if code != 0 or not out:
        return None
    base32_hash = out.splitlines()[-1].strip()
    sri_out, code = run_cmd(f"nix hash convert --to sri --hash-algo sha256 '{base32_hash}'")
    if code != 0 or not sri_out:
        return None
    return sri_out.strip()
