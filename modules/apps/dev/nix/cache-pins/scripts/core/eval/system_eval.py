"""NixOS system toplevel evaluation and missing closure / FOD discovery."""

import json
import os
from pathlib import Path
import re
import socket
import subprocess
import sys
from typing import Dict, List, Optional, Tuple

from core.eval.channels import find_flake_dir, get_nix_env
from core.eval.resolver import is_path_in_nix_store
from core.models import FodDownloadItem


def get_system_hostname(flake_dir: Optional[Path] = None) -> str:
    """Resolve current NixOS hostname dynamically from environment, /etc/hostname, socket, or flake configurations."""
    # 1. Environment override
    env_host = os.environ.get("NIXOS_HOST") or os.environ.get("HOSTNAME")
    if env_host and env_host.strip():
        return env_host.strip()

    # 2. Read /etc/hostname directly
    try:
        etc_host_file = Path("/etc/hostname")
        if etc_host_file.is_file():
            host = etc_host_file.read_text(encoding="utf-8").strip()
            if host:
                return host
    except Exception:
        pass

    # 3. Socket hostname
    socket_host = None
    try:
        sh = socket.gethostname()
        if sh and sh.strip():
            socket_host = sh.strip()
    except Exception:
        pass

    # 4. Flake configuration discovery
    root_dir = flake_dir or find_flake_dir()
    if root_dir:
        flake_nix = root_dir / "flake.nix"
        if flake_nix.is_file():
            try:
                content = flake_nix.read_text(encoding="utf-8")
                matches = re.findall(r"nixosConfigurations\.([a-zA-Z0-9_-]+)", content)
                if matches:
                    if socket_host and socket_host in matches:
                        return socket_host
                    # If socket hostname matches case-insensitively
                    if socket_host:
                        for m in matches:
                            if m.lower() == socket_host.lower():
                                return m
                    return matches[0]
            except Exception:
                pass

    return socket_host or "nixos"


def get_system_toplevel_attr(
    flake_dir: Optional[Path] = None, hostname: Optional[str] = None
) -> str:
    """Get flake target attribute for system toplevel."""
    host = hostname or get_system_hostname(flake_dir)
    return f".#nixosConfigurations.{host}.config.system.build.toplevel"


def extract_missing_fods(
    drv_paths: List[str], env: Optional[Dict[str, str]] = None
) -> List[FodDownloadItem]:
    """Inspect derivations using `nix show-derivation` and identify missing Fixed-Output Derivations (FODs)."""
    if not drv_paths:
        return []

    cmd = ["nix", "show-derivation"] + drv_paths
    res = subprocess.run(cmd, capture_output=True, text=True, env=env or get_nix_env())
    if res.returncode != 0 or not res.stdout.strip():
        return []

    try:
        data = json.loads(res.stdout)
    except Exception:
        return []

    drvs = data.get("derivations", data)
    missing_fods: List[FodDownloadItem] = []

    for drv_path, drv in drvs.items():
        if not isinstance(drv, dict):
            continue

        env_map = drv.get("env", {})
        attrs = drv.get("structuredAttrs", {})

        output_hash = env_map.get("outputHash") or attrs.get("outputHash")
        if not output_hash:
            continue

        output_hash_algo = env_map.get("outputHashAlgo") or attrs.get("outputHashAlgo") or "sha256"
        output_hash_mode = env_map.get("outputHashMode") or attrs.get("outputHashMode", "flat")

        raw_urls = attrs.get("urls") or env_map.get("urls") or []
        if isinstance(raw_urls, str):
            urls = raw_urls.split()
        elif isinstance(raw_urls, list):
            urls = raw_urls
        else:
            urls = []

        if not urls:
            continue

        out_path = env_map.get("out") or drv.get("outputs", {}).get("out", {}).get("path")
        if not out_path:
            continue

        if is_path_in_nix_store(out_path):
            continue

        filename = os.path.basename(out_path)
        parts = filename.split("-", 1)
        pure_filename = parts[1] if len(parts) == 2 and len(parts[0]) == 32 else filename

        url = urls[0]
        url_path = url.split("?")[0].split("#")[0]
        url_file = os.path.basename(url_path)
        download_filename = url_file if url_file else pure_filename

        post_fetch = attrs.get("postFetch") or env_map.get("postFetch")
        strip_root_val = attrs.get("stripRoot") if "stripRoot" in attrs else env_map.get("stripRoot")
        if strip_root_val is not None:
            if isinstance(strip_root_val, bool):
                strip_root = strip_root_val
            elif isinstance(strip_root_val, str):
                strip_root = strip_root_val.lower() not in ("0", "false", "no")
            elif isinstance(strip_root_val, int):
                strip_root = bool(strip_root_val)
            else:
                strip_root = True
        else:
            strip_root = True

        item = FodDownloadItem(
            drv_path=drv_path,
            out_path=out_path,
            url=url,
            filename=pure_filename,
            hash_algo=output_hash_algo,
            hash_value=output_hash,
            hash_mode=output_hash_mode,
            download_filename=download_filename,
            strip_root=strip_root,
            post_fetch=post_fetch,
        )
        missing_fods.append(item)

    return missing_fods


def evaluate_system_missing_paths(
    flake_dir: Optional[Path] = None,
    hostname: Optional[str] = None,
    verbose: bool = False,
) -> Tuple[List[str], List[FodDownloadItem], Dict[str, str]]:
    """Run dry-run build on system toplevel and parse store paths that must be fetched or built via FOD.

    Returns:
        Tuple of (missing_substituter_paths, missing_fods, summary_metadata)
    """
    root_dir = flake_dir or find_flake_dir()
    if not root_dir:
        raise RuntimeError("Direktori flake (berisi flake.nix) tidak ditemukan.")

    target_attr = get_system_toplevel_attr(root_dir, hostname)
    cmd = ["nix", "build", "--dry-run", target_attr]

    env = get_nix_env()

    if verbose:
        print(f"🔧 Menjalankan: {' '.join(cmd)} (di {root_dir})", file=sys.stderr)

    # Jalankan subprocess secara streaming agar terminal tidak freeze/stuck
    proc = subprocess.Popen(
        cmd,
        cwd=str(root_dir),
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
        universal_newlines=True,
        env=env,
    )

    output_lines: List[str] = []
    last_status_len = 0

    def update_status(text: str):
        nonlocal last_status_len
        clean_text = text.strip().replace("\n", " ")
        if len(clean_text) > 75:
            clean_text = clean_text[:72] + "..."
        msg = f"\r   ⏳ {clean_text}"
        pad = max(0, last_status_len - len(msg))
        sys.stderr.write(msg + (" " * pad))
        sys.stderr.flush()
        last_status_len = len(msg)

    def clear_status():
        nonlocal last_status_len
        if last_status_len > 0:
            sys.stderr.write(f"\r{' ' * last_status_len}\r")
            sys.stderr.flush()
            last_status_len = 0

    try:
        if proc.stdout:
            for line in iter(proc.stdout.readline, ""):
                output_lines.append(line)
                stripped = line.strip()
                if not stripped:
                    continue
                if verbose:
                    print(f"   {stripped}", file=sys.stderr)
                else:
                    if (
                        stripped.startswith("evaluating")
                        or stripped.startswith("copying")
                        or stripped.startswith("downloading")
                        or stripped.startswith("fetching")
                    ):
                        update_status(stripped)
                    elif (
                        "warning:" in stripped.lower()
                        or "error:" in stripped.lower()
                    ):
                        clear_status()
                        print(f"   ⚠️  {stripped}", file=sys.stderr)
        proc.wait()
    except KeyboardInterrupt:
        clear_status()
        proc.terminate()
        raise
    finally:
        clear_status()

    if proc.returncode != 0:
        clear_status()
        print(
            f"❌ ERROR: Evaluasi sistem Nix gagal (exit code {proc.returncode}):",
            file=sys.stderr,
        )
        for err_l in output_lines[-20:]:
            print(f"   {err_l.strip()}", file=sys.stderr)
        sys.exit(proc.returncode or 1)

    output = "".join(output_lines)

    missing_paths: List[str] = []
    candidate_drvs: List[str] = []
    in_fetch_section = False
    in_build_section = False

    metadata: Dict[str, str] = {
        "target": target_attr,
        "summary": "0 paket (seluruh biner sudah ada di lokal)",
        "download_size": "0 B",
        "unpacked_size": "0 B",
    }

    for line in output.splitlines():
        line_clean = line.strip()

        # Check section header: "these N paths will be fetched (...):" or "this path will be fetched (...):"
        fetch_match = re.search(
            r"\b(?:these \d+|this) path(?:s)? will be fetched \(([^)]+)\):?",
            line_clean,
            re.IGNORECASE,
        )
        if fetch_match:
            in_fetch_section = True
            in_build_section = False
            size_info = fetch_match.group(1)
            metadata["summary"] = size_info
            parts = [p.strip() for p in size_info.split(",")]
            for p in parts:
                if "download" in p:
                    metadata["download_size"] = p.replace("download", "").strip()
                elif "unpacked" in p:
                    metadata["unpacked_size"] = p.replace("unpacked", "").strip()
            continue

        build_match = re.search(
            r"\b(?:these \d+|this) derivation(?:s)? will be built:?",
            line_clean,
            re.IGNORECASE,
        )
        if build_match:
            in_build_section = True
            in_fetch_section = False
            continue

        if in_fetch_section:
            if line.startswith(" ") or line.startswith("\t"):
                if line_clean.startswith("/nix/store/"):
                    sp = line_clean.split()[0]
                    if sp not in missing_paths:
                        missing_paths.append(sp)
            elif line_clean.startswith("these ") or line_clean.startswith("this "):
                in_fetch_section = False

        if in_build_section:
            if line.startswith(" ") or line.startswith("\t"):
                if line_clean.startswith("/nix/store/") and line_clean.endswith(".drv"):
                    drv_p = line_clean.split()[0]
                    if drv_p not in candidate_drvs:
                        candidate_drvs.append(drv_p)
            elif line_clean.startswith("these ") or line_clean.startswith("this "):
                in_build_section = False

    missing_fods = extract_missing_fods(candidate_drvs, env=env)
    return missing_paths, missing_fods, metadata
