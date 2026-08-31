"""Single-pass batch Nix evaluator and single package evaluation runner."""
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import threading
from typing import Any, Dict, List, Optional, Tuple

from core.eval.channels import (
    find_flake_dir,
    get_nix_env,
    resolve_channel_input,
)
from core.platform import get_current_system
from core.eval.resolver import (
    build_nix_batch_eval_expression,
    extract_version_from_store_path,
    generate_candidate_names,
    is_path_in_nix_store,
)
from core.models import PackageMeta


def eval_nix_raw(
    expr: str,
    flake_input: Optional[str] = None,
    system: Optional[str] = None,
    verbose: Optional[bool] = None,
    timeout: Optional[int] = None,
) -> Optional[str]:
    """Evaluate a raw Nix expression via 'nix eval --raw' with progress feedback and return trimmed string."""
    flake_dir = find_flake_dir()
    flake_prefix = f"{flake_dir}#" if flake_dir else ""
    target_system = system or get_current_system()

    cmd = ["nix", "eval", "--raw", "--impure"]

    if flake_input and not expr.startswith("builtins.") and not expr.startswith("import"):
        if flake_input.startswith("/nix/store/") or flake_input.startswith("path:"):
            clean_path = flake_input.replace("path:", "")
            eval_expr = f'(builtins.getFlake "path:{clean_path}").legacyPackages.{target_system}.{expr}'
        elif any(flake_input.startswith(prefix) for prefix in ["github:", "gitlab:", "git+", "git:"]):
            eval_expr = f'(builtins.getFlake "{flake_input}").legacyPackages.{target_system}.{expr}'
        else:
            eval_expr = f'(builtins.getFlake "{flake_prefix}").inputs.{flake_input}.legacyPackages.{target_system}.{expr}'
        cmd.extend(["--expr", eval_expr])
    else:
        cmd.extend(["--expr", expr])

    is_verbose = verbose if verbose is not None else (os.environ.get("NCP_VERBOSE") == "1")
    is_tty = sys.stderr.isatty()

    try:
        proc = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            bufsize=1,
            env=get_nix_env(),
        )

        stdout_chunks = []
        stderr_lines = []

        def handle_stderr():
            for raw_line in iter(proc.stderr.readline, ""):
                if not raw_line:
                    break
                line = raw_line.strip()
                if not line:
                    continue
                stderr_lines.append(line)
                if is_verbose:
                    print(f"  [nix] {line}", file=sys.stderr, flush=True)
                elif is_tty:
                    short_line = line[:80]
                    print(f"\033[2K\r  ⏳ {short_line}", file=sys.stderr, end="", flush=True)

        def handle_stdout():
            for raw_line in iter(proc.stdout.readline, ""):
                if not raw_line:
                    break
                stdout_chunks.append(raw_line)

        t_err = threading.Thread(target=handle_stderr, daemon=True)
        t_out = threading.Thread(target=handle_stdout, daemon=True)
        t_err.start()
        t_out.start()

        if timeout is not None:
            proc.wait(timeout=timeout)
        else:
            proc.wait()

        t_err.join(timeout=2)
        t_out.join(timeout=2)

        if is_tty and not is_verbose:
            print("\033[2K\r", file=sys.stderr, end="", flush=True)

        if proc.returncode == 0:
            return "".join(stdout_chunks).strip()
        elif not is_verbose and stderr_lines:
            err_summary = "\n".join(stderr_lines[-3:])
            print(f"  ⚠️  [nix eval error]: {err_summary}", file=sys.stderr)
    except subprocess.TimeoutExpired:
        try:
            proc.kill()
        except Exception:
            pass
        if is_tty and not is_verbose:
            print("\033[2K\r", file=sys.stderr, end="", flush=True)
    except Exception:
        if is_tty and not is_verbose:
            print("\033[2K\r", file=sys.stderr, end="", flush=True)

    return None


def evaluate_batch(
    targets: Dict[str, Optional[str]],
    nixpkgs_input: str = "nixpkgs",
    system: Optional[str] = None,
    verbose: Optional[bool] = None,
    timeout: Optional[int] = None,
) -> Dict[str, Optional[PackageMeta]]:
    """Evaluate multiple package targets in a single-pass atomic Nix expression."""
    if not targets:
        return {}

    effective_system = system or get_current_system()
    flake_dir = find_flake_dir()
    flake_prefix = f"{flake_dir}#" if flake_dir else ""

    if nixpkgs_input.startswith("/nix/store/") or nixpkgs_input.startswith("path:"):
        clean_path = nixpkgs_input.replace("path:", "")
        flake_target_expr = f'(builtins.getFlake "path:{clean_path}")'
    elif any(nixpkgs_input.startswith(prefix) for prefix in ["github:", "gitlab:", "git+", "git:"]):
        flake_target_expr = f'(builtins.getFlake "{nixpkgs_input}")'
    else:
        flake_target_expr = f'(builtins.getFlake "{flake_prefix}").inputs.{nixpkgs_input}'

    target_candidates_map = {}
    clean_to_orig_key = {}

    for orig_key, pname in targets.items():
        clean_key = orig_key.replace("pkgs.", "").strip()
        cands = generate_candidate_names(clean_key, pname)
        target_candidates_map[clean_key] = cands
        clean_to_orig_key[clean_key] = orig_key

    expr = build_nix_batch_eval_expression(target_candidates_map, flake_target_expr, system=effective_system)
    cmd = ["nix", "eval", "--json", "--impure", "--expr", expr]

    is_verbose = verbose if verbose is not None else (os.environ.get("NCP_VERBOSE") == "1")
    is_tty = sys.stderr.isatty()

    results: Dict[str, Optional[PackageMeta]] = {k: None for k in targets}

    try:
        proc = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            bufsize=1,
            env=get_nix_env(),
        )

        stdout_chunks = []
        stderr_lines = []

        def handle_stderr():
            for raw_line in iter(proc.stderr.readline, ""):
                if not raw_line:
                    break
                line = raw_line.strip()
                if not line:
                    continue
                stderr_lines.append(line)
                if is_verbose:
                    print(f"  [nix eval] {line}", file=sys.stderr, flush=True)
                elif is_tty:
                    short_line = line[:80]
                    print(f"\033[2K\r  ⏳ {short_line}", file=sys.stderr, end="", flush=True)

        def handle_stdout():
            for raw_line in iter(proc.stdout.readline, ""):
                if not raw_line:
                    break
                stdout_chunks.append(raw_line)

        t_err = threading.Thread(target=handle_stderr, daemon=True)
        t_out = threading.Thread(target=handle_stdout, daemon=True)
        t_err.start()
        t_out.start()

        if timeout is not None:
            proc.wait(timeout=timeout)
        else:
            proc.wait()

        t_err.join(timeout=2)
        t_out.join(timeout=2)

        if is_tty and not is_verbose:
            print("\033[2K\r", file=sys.stderr, end="", flush=True)

        if proc.returncode == 0:
            raw_out = "".join(stdout_chunks).strip()
            if raw_out and raw_out != "null":
                data = json.loads(raw_out)
                if isinstance(data, dict):
                    for clean_key, meta in data.items():
                        orig_key = clean_to_orig_key.get(clean_key, clean_key)
                        if isinstance(meta, dict) and "storePath" in meta and meta["storePath"]:
                            sp = meta["storePath"]
                            ver = meta.get("version") or extract_version_from_store_path(sp)
                            results[orig_key] = PackageMeta(
                                store_path=sp,
                                version=ver,
                                main_program=meta.get("mainProgram"),
                                pname=meta.get("pname"),
                                system=effective_system,
                                channel=nixpkgs_input,
                            )
        elif not is_verbose and stderr_lines:
            err_summary = "\n".join(stderr_lines[-3:])
            print(f"  ⚠️  [nix eval error]: {err_summary}", file=sys.stderr)
    except subprocess.TimeoutExpired:
        try:
            proc.kill()
        except Exception:
            pass
        if is_tty and not is_verbose:
            print("\033[2K\r", file=sys.stderr, end="", flush=True)
    except Exception as e:
        if is_tty and not is_verbose:
            print("\033[2K\r", file=sys.stderr, end="", flush=True)
        if is_verbose:
            print(f"Error during batch eval: {e}", file=sys.stderr)

    return results


def evaluate_single_package(
    target_key: str,
    nixpkgs_input: str = "nixpkgs",
    pname: Optional[str] = None,
    system: Optional[str] = None,
    verbose: Optional[bool] = None,
) -> Tuple[Optional[str], str, Optional[str]]:
    """Evaluate a single package and return (store_path, version, main_program) tuple."""
    eval_target = nixpkgs_input
    if not (nixpkgs_input.startswith("/nix/store/") or nixpkgs_input.startswith("path:")):
        try:
            from core.cache.tracker import get_channel_revision_info
            rev_info = get_channel_revision_info(nixpkgs_input)
            if rev_info.store_path and os.path.exists(rev_info.store_path):
                eval_target = rev_info.store_path
            elif rev_info.locked_url:
                eval_target = rev_info.locked_url
        except Exception:
            pass

    batch_res = evaluate_batch(
        targets={target_key: pname},
        nixpkgs_input=eval_target,
        system=system,
        verbose=verbose,
    )
    meta = batch_res.get(target_key)
    if meta and meta.store_path:
        return meta.store_path, meta.version, meta.main_program
    return None, "unknown", None


def evaluate_upstream_package(
    target_key: str,
    nixpkgs_input: str = "nixpkgs",
    pname: Optional[str] = None,
    system: Optional[str] = None,
    verbose: Optional[bool] = None,
) -> Tuple[Optional[str], str, Optional[str]]:
    """Compatibility alias for evaluate_single_package."""
    return evaluate_single_package(
        target_key=target_key,
        nixpkgs_input=nixpkgs_input,
        pname=pname,
        system=system,
        verbose=verbose,
    )


def resolve_target_to_store_path(
    target: str,
    nixpkgs_input: str = "nixpkgs",
    pins_file: Optional[Path] = None,
    system: Optional[str] = None,
    prefer_pin: bool = False,
    explicit_input: bool = False,
) -> Tuple[str, str, Optional[str]]:
    """Resolve a target name, attr, or store path into a validated (store_path, version, main_program) tuple."""
    # 1. Direct Store Path
    if target.startswith("/nix/store/"):
        store_path = target.rstrip("/")
        version = extract_version_from_store_path(store_path)
        return store_path, version, None

    clean_target = target.replace("pkgs.", "").strip()
    var_dash = clean_target.replace("_", "-")
    var_under = clean_target.replace("-", "_")

    cached_pname = None
    cached_entry = None
    cached_channel = None

    if pins_file and pins_file.is_file():
        try:
            from registry.store import load_cache_pins
            pins_data = load_cache_pins(pins_file)
            for key_candidate in [clean_target, var_dash, var_under]:
                if key_candidate in pins_data:
                    cached_entry = pins_data[key_candidate]
                    if isinstance(cached_entry, dict):
                        cached_pname = cached_entry.get("pname")
                        cached_channel = cached_entry.get("channel")
                    break
        except Exception:
            pass

    # 2. Prioritaskan pin lokal jika prefer_pin=True dan tidak ada override channel eksplisit
    if prefer_pin and not explicit_input and cached_entry and isinstance(cached_entry, dict) and "storePath" in cached_entry:
        sp = cached_entry["storePath"]
        ver = cached_entry.get("version") or extract_version_from_store_path(sp)
        main_prog = cached_entry.get("mainProgram")
        return sp, ver, main_prog

    # 3. Tentukan effective input channel
    if not explicit_input and cached_channel:
        effective_input = resolve_channel_input(cached_channel)
    else:
        effective_input = nixpkgs_input

    # 4. Evaluate from requested channel/input
    sp, ver, main_prog = evaluate_single_package(
        target_key=clean_target,
        nixpkgs_input=effective_input,
        pname=cached_pname,
        system=system,
    )
    if sp and sp.startswith("/nix/store/"):
        return sp, ver, main_prog

    # 5. Fallback: use local pin entry if upstream evaluation is unresolvable
    if cached_entry and isinstance(cached_entry, dict) and "storePath" in cached_entry:
        sp = cached_entry["storePath"]
        ver = cached_entry.get("version") or extract_version_from_store_path(sp)
        main_prog = cached_entry.get("mainProgram")
        return sp, ver, main_prog

    raise RuntimeError(
        f"Tidak dapat menemukan store path untuk '{target}' pada channel/input '{effective_input}'. "
        "Pastikan nama atribut valid atau terdaftar di modules/_lib/cache-pins.nix."
    )
