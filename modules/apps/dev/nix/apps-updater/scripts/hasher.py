import json
from utils import run_cmd

def compute_sri_hash(url, unpack=False):
    """Mengunduh biner dan menghitung sha256 SRI hash (sha256-...)."""
    flag = "--unpack" if unpack else ""
    print(f"  ⬇️  Mengunduh & menghitung hash {'(unpacked) ' if unpack else ''}untuk: {url}")
    # Prioritas 1: Gunakan nix store prefetch-file --json
    cmd = f"nix store prefetch-file {flag} --json '{url}'" if flag else f"nix store prefetch-file --json '{url}'"
    out, code = run_cmd(cmd)
    if code == 0 and out:
        try:
            data = json.loads(out)
            if "hash" in data:
                return data["hash"].strip()
        except Exception:
            pass

    # Prioritas 2: Fallback ke nix-prefetch-url + nix hash convert
    prefetch_cmd = f"nix-prefetch-url {flag} '{url}'" if flag else f"nix-prefetch-url '{url}'"
    out, code = run_cmd(prefetch_cmd)
    if code != 0 or not out:
        return None
    base32_hash = out.splitlines()[-1].strip()
    sri_out, code = run_cmd(f"nix hash convert --to sri --hash-algo sha256 '{base32_hash}'")
    if code != 0 or not sri_out:
        return None
    return sri_out.strip()
