"""Smart module adoption and AST patching to refactor modules to selfLib.fetchCachePinned."""
from pathlib import Path
import re
import subprocess
from typing import List, Optional

from core.nix_eval import find_flake_dir


def find_modules_referencing_pkg(pkg_name: str, base_dir: Optional[Path] = None) -> List[Path]:
    """Find .nix files under modules/ that reference pkgs.<pkg_name>."""
    root = base_dir or find_flake_dir()
    if not root:
        return []

    modules_dir = root / "modules"
    if not modules_dir.is_dir():
        modules_dir = root

    clean_pkg = pkg_name.replace("pkgs.", "")
    var_dash = clean_pkg.replace("_", "-")
    var_under = clean_pkg.replace("-", "_")

    patterns = [
        rf"\bpkgs\.{re.escape(clean_pkg)}\b",
        rf"\bpkgs\.{re.escape(var_dash)}\b",
        rf"\bpkgs\.{re.escape(var_under)}\b",
        rf"\bpkgs\.\"{re.escape(clean_pkg)}\"",
        rf"\bpkgs\.\"{re.escape(var_dash)}\"",
        rf"\bpkgs\.\"{re.escape(var_under)}\"",
    ]

    matched_files: List[Path] = []
    for p in modules_dir.rglob("*.nix"):
        if "modules/_lib" in str(p) or "modules/apps/dev/nix/cache-pins" in str(p):
            continue
        try:
            content = p.read_text(encoding="utf-8")
            if any(re.search(pat, content) for pat in patterns):
                matched_files.append(p)
        except Exception:
            continue

    return matched_files


def adopt_module_pin(module_file: Path, pkg_name: str) -> bool:
    """Refactor a module .nix file to use selfLib.fetchCachePinned for the given package."""
    if not module_file.is_file():
        raise FileNotFoundError(f"Berkas modul tidak ditemukan: {module_file}")

    content = module_file.read_text(encoding="utf-8")
    clean_pkg = pkg_name.replace("pkgs.", "")
    var_dash = clean_pkg.replace("_", "-")
    var_under = clean_pkg.replace("-", "_")

    # 1. Pastikan selfLib ada di argumen fungsi header
    header_match = re.search(r"^\s*\{([^\}]*)\}\s*:", content, re.MULTILINE)
    if header_match:
        args_text = header_match.group(1)
        if "selfLib" not in args_text:
            new_args = "  selfLib,\n" + args_text.lstrip()
            content = content[: header_match.start(1)] + new_args + content[header_match.end(1) :]

    # 2. Ganti pemanggilan pkgs.<pkg> menjadi (selfLib.fetchCachePinned "<var_under>")
    patterns = [
        rf"\bpkgs\.{re.escape(clean_pkg)}\b",
        rf"\bpkgs\.{re.escape(var_dash)}\b",
        rf"\bpkgs\.{re.escape(var_under)}\b",
        rf"\bpkgs\.\"{re.escape(clean_pkg)}\"",
        rf"\bpkgs\.\"{re.escape(var_dash)}\"",
        rf"\bpkgs\.\"{re.escape(var_under)}\"",
    ]

    modified = False
    for pat in patterns:
        if re.search(pat, content):
            content = re.sub(pat, f'(selfLib.fetchCachePinned "{var_under}")', content)
            modified = True

    if not modified:
        return False

    # Bersihkan double parenthesis jika ada, misal ((selfLib...))
    content = re.sub(
        rf"\(\((selfLib\.fetchCachePinned \"{re.escape(var_under)}\")\)\)", r"(\1)", content
    )

    module_file.write_text(content, encoding="utf-8")

    # Run nixfmt
    try:
        subprocess.run(["nixfmt", str(module_file)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass

    return True
