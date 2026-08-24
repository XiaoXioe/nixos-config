"""CRUD operations for modules/_lib/cache-pins.nix file with automatic nixfmt formatting."""
import json
import os
from pathlib import Path
import re
import subprocess
import sys
from typing import Any, Dict, List, Optional


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


def write_or_update_pin(pins_file: Path, target_key: str, snippet: str) -> bool:
    """Write or update a pin entry in cache-pins.nix and re-format with nixfmt."""
    if not pins_file.is_file():
        raise FileNotFoundError(f"Berkas pin tidak ditemukan: {pins_file}")

    content = pins_file.read_text(encoding="utf-8")
    clean_key = re.sub(r"[^a-zA-Z0-9_]", "_", target_key.replace("pkgs.", ""))

    # Regex matching existing block with preceding comments
    pattern = re.compile(
        rf"(?m)((?:^[ \t]*#[^\n]*\n)*^[ \t]*{re.escape(clean_key)}\s*=\s*\{{.*?\n[ \t]*\}};\n?)",
        re.DOTALL,
    )
    match = pattern.search(content)

    formatted_snippet = "\n" + snippet.strip() + "\n"

    if match:
        new_content = content[: match.start()] + formatted_snippet + content[match.end() :]
    else:
        footer_comment_match = re.search(r"(?m)^[ \t]*#[ \t]*──[ \t]*Tambah entri lain", content)
        if footer_comment_match:
            insert_pos = footer_comment_match.start()
            new_content = content[:insert_pos] + formatted_snippet + "\n" + content[insert_pos:]
        else:
            last_brace_idx = content.rfind("}")
            if last_brace_idx != -1:
                new_content = content[:last_brace_idx] + formatted_snippet + content[last_brace_idx:]
            else:
                new_content = content + "\n" + formatted_snippet

    pins_file.write_text(new_content, encoding="utf-8")

    # Run nixfmt if available
    try:
        subprocess.run(["nixfmt", str(pins_file)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass

    return True


def delete_pin_entry(pins_file: Path, target_key: str) -> bool:
    """Delete a pin entry and its preceding comment block from cache-pins.nix and re-format with nixfmt."""
    if not pins_file.is_file():
        raise FileNotFoundError(f"Berkas pin tidak ditemukan: {pins_file}")

    content = pins_file.read_text(encoding="utf-8")
    clean_key = re.sub(r"[^a-zA-Z0-9_]", "_", target_key.replace("pkgs.", ""))

    # Regex matching existing block with comments
    pattern = re.compile(
        rf"(?m)((?:^[ \t]*#[^\n]*\n)*^[ \t]*{re.escape(clean_key)}\s*=\s*\{{.*?\n[ \t]*\}};\n?)",
        re.DOTALL,
    )
    match = pattern.search(content)
    if not match:
        return False

    new_content = content[: match.start()] + content[match.end() :]
    pins_file.write_text(new_content, encoding="utf-8")

    # Run nixfmt if available
    try:
        subprocess.run(["nixfmt", str(pins_file)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass

    return True
