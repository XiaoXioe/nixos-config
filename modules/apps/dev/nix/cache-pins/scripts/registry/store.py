"""CRUD operations and atomic file management for modules/_lib/cache-pins.nix."""
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
from typing import Any, Dict, List, Optional

from core.eval.channels import get_nix_env


def load_cache_pins(pins_file: Path) -> Dict[str, Dict[str, Any]]:
    """Load all pin entries from cache-pins.nix as a parsed Python dictionary."""
    if not pins_file.is_file():
        return {}
    expr = f"import {pins_file}"
    try:
        res = subprocess.run(
            ["nix", "eval", "--json", "--impure", "--expr", expr],
            capture_output=True,
            text=True,
            timeout=30,
            env=get_nix_env(),
        )
        if res.returncode == 0:
            return json.loads(res.stdout)
    except Exception as e:
        print(f"Error loading {pins_file}: {e}", file=sys.stderr)
    return {}


def get_all_pin_keys(pins_file: Path) -> List[str]:
    """Get a sorted list of all attribute pin keys in cache-pins.nix."""
    data = load_cache_pins(pins_file)
    return sorted(list(data.keys()))


def load_pin_sources(pins_file: Path) -> Dict[str, str]:
    """Extract the original Source channel/input comment for each pin in cache-pins.nix."""
    if not pins_file.is_file():
        return {}

    content = pins_file.read_text(encoding="utf-8")
    sources: Dict[str, str] = {}

    pattern = re.compile(
        r"(?:#[^\n]*Source:\s*([^\n|#]+)[^\n]*\n(?:#[^\n]*\n)*)\s*([a-zA-Z0-9_-]+)\s*=\s*\{"
    )
    for match in pattern.finditer(content):
        src = match.group(1).strip()
        attr = match.group(2).strip()
        if "(" in src:
            m_sub = re.search(r"\(([^)]+)\)", src)
            if m_sub:
                src = m_sub.group(1).strip()
        sources[attr] = src

    return sources


def _atomic_write_and_format(pins_file: Path, content: str) -> bool:
    """Write content to a temporary file in the same directory, format with nixfmt, and atomically replace."""
    parent_dir = pins_file.parent
    tmp_path = parent_dir / f".{pins_file.name}.tmp.{os.getpid()}"

    try:
        tmp_path.write_text(content, encoding="utf-8")

        # Run nixfmt if available
        try:
            subprocess.run(
                ["nixfmt", str(tmp_path)],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                timeout=10,
            )
        except Exception:
            pass

        # Atomic replacement
        tmp_path.replace(pins_file)
        return True
    except Exception as e:
        if tmp_path.exists():
            try:
                tmp_path.unlink()
            except Exception:
                pass
        raise IOError(f"Gagal menulis berkas pin secara atomik: {e}")


def write_or_update_pins_batch(pins_file: Path, snippets_map: Dict[str, str]) -> bool:
    """Write or update multiple pin entries in cache-pins.nix in a single atomic pass."""
    if not pins_file.is_file():
        raise FileNotFoundError(f"Berkas pin tidak ditemukan: {pins_file}")
    if not snippets_map:
        return True

    content = pins_file.read_text(encoding="utf-8")

    for target_key, snippet in snippets_map.items():
        clean_key = re.sub(r"[^a-zA-Z0-9_]", "_", target_key.replace("pkgs.", "").strip())
        formatted_snippet = "\n" + snippet.strip() + "\n"

        pattern = re.compile(
            rf"(?m)((?:^[ \t]*#[^\n]*\n)*^[ \t]*{re.escape(clean_key)}\s*=\s*\{{.*?\n[ \t]*\}};\n?)",
            re.DOTALL,
        )
        match = pattern.search(content)

        if match:
            content = content[: match.start()] + formatted_snippet + content[match.end() :]
        else:
            footer_comment_match = re.search(r"(?m)^[ \t]*#[ \t]*──[ \t]*Tambah entri lain", content)
            if footer_comment_match:
                insert_pos = footer_comment_match.start()
                content = content[:insert_pos] + formatted_snippet + "\n" + content[insert_pos:]
            else:
                last_brace_idx = content.rfind("}")
                if last_brace_idx != -1:
                    content = content[:last_brace_idx] + formatted_snippet + content[last_brace_idx:]
                else:
                    content = content + "\n" + formatted_snippet

    return _atomic_write_and_format(pins_file, content)


def write_or_update_pin(pins_file: Path, target_key: str, snippet: str) -> bool:
    """Write or update a single pin entry in cache-pins.nix atomically."""
    return write_or_update_pins_batch(pins_file, {target_key: snippet})


def delete_pin_entry(pins_file: Path, target_key: str) -> bool:
    """Delete a pin entry and its preceding comment block from cache-pins.nix atomically."""
    if not pins_file.is_file():
        raise FileNotFoundError(f"Berkas pin tidak ditemukan: {pins_file}")

    content = pins_file.read_text(encoding="utf-8")
    clean_key = re.sub(r"[^a-zA-Z0-9_]", "_", target_key.replace("pkgs.", "").strip())

    pattern = re.compile(
        rf"(?m)((?:^[ \t]*#[^\n]*\n)*^[ \t]*{re.escape(clean_key)}\s*=\s*\{{.*?\n[ \t]*\}};\n?)",
        re.DOTALL,
    )
    match = pattern.search(content)
    if not match:
        return False

    new_content = content[: match.start()] + content[match.end() :]
    return _atomic_write_and_format(pins_file, new_content)
