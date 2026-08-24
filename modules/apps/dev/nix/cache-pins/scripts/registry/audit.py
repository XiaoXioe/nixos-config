"""Scanner for detecting active vs unused (dangling) cache pins across NixOS modules."""
from pathlib import Path
import re
from typing import Dict, List, Optional, Tuple

from core.nix_eval import find_flake_dir
from registry.store import load_cache_pins


def find_unused_pins(
    pins_file: Path, base_dir: Optional[Path] = None
) -> Tuple[Dict[str, List[str]], List[str]]:
    """Scan the NixOS repository modules to identify which cache pins are active and which are dangling."""
    pins_data = load_cache_pins(pins_file)
    pin_keys = list(pins_data.keys())

    root = base_dir or find_flake_dir()
    if not root:
        root = pins_file.parent.parent

    modules_dir = root / "modules"
    if not modules_dir.is_dir():
        modules_dir = root

    used_map: Dict[str, List[str]] = {k: [] for k in pin_keys}

    ignore_files = {
        pins_file.resolve(),
        (root / "modules" / "_lib" / "default.nix").resolve(),
        (root / "modules" / "_lib" / "modules" / "fetchNixCache" / "default.nix").resolve(),
    }

    nix_files: List[Path] = []
    for p in modules_dir.rglob("*.nix"):
        if p.resolve() in ignore_files:
            continue
        if "modules/apps/dev/nix/cache-pins" in str(p.resolve()):
            continue
        nix_files.append(p)

    for nfile in nix_files:
        try:
            content = nfile.read_text(encoding="utf-8")
        except Exception:
            continue

        rel_path = str(nfile.relative_to(root)) if root in nfile.parents else str(nfile)

        # 1. Cari pemanggilan fetchCachePinned (string tunggal atau list of strings/pkgs)
        for match in re.finditer(
            r"fetchCachePinned\s+(?:pkgs\s+)?(\[[^\]]*\]|\"[^\"]+\")", content, re.DOTALL
        ):
            snippet = match.group(1)
            found_strings = re.findall(r"\"([a-zA-Z0-9_-]+)\"", snippet)
            found_pkgs = re.findall(r"(?:pkgs\.)([a-zA-Z0-9_-]+)", snippet)
            for s in found_strings + found_pkgs:
                clean_s = s.replace("-", "_")
                if s in used_map:
                    used_map[s].append(rel_path)
                elif clean_s in used_map:
                    used_map[clean_s].append(rel_path)

        # 2. Cari akses atribut cachePins.<name> atau cachePins."<name>"
        for match in re.finditer(
            r"cachePins\.([a-zA-Z0-9_-]+)|\bcachePins\.\"([a-zA-Z0-9_-]+)\"", content
        ):
            k = match.group(1) or match.group(2)
            if k in used_map:
                used_map[k].append(rel_path)

    # Deduplikasi daftar file referensi
    for k in used_map:
        used_map[k] = sorted(list(set(used_map[k])))

    unused = [k for k, refs in used_map.items() if len(refs) == 0]
    used = {k: refs for k, refs in used_map.items() if len(refs) > 0}

    return used, unused
