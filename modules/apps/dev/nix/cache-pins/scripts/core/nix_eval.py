"""Nix evaluation utilities: store path resolution, channel normalization, and discovery."""
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import threading
from typing import Any, Dict, Optional, Tuple


def find_flake_dir() -> Optional[Path]:
    """Find root directory containing flake.nix / flake.lock."""
    cwd = Path.cwd()
    for parent in [cwd] + list(cwd.parents):
        if (parent / "flake.nix").is_file():
            return parent.resolve()
    home = Path.home()
    for candidate in [
        home / "nixos-config",
        home / ".config" / "nixos",
        Path("/etc/nixos"),
    ]:
        if (candidate / "flake.nix").is_file():
            return candidate.resolve()
    return None


def resolve_channel_input(channel_or_input: Optional[str]) -> str:
    """Normalize user channel shorthand or flake input name to full flake input URL."""
    if not channel_or_input:
        return "nixpkgs"

    val = channel_or_input.strip()

    # Local filesystem path
    if val.startswith("/") or val.startswith("./") or val.startswith("../"):
        return f"path:{Path(val).resolve()}"

    # Direct flake URLs or references with : or /
    if ":" in val or "/" in val:
        return val

    mapping = {
        "nixpkgs": "nixpkgs",
        "unstable": "github:NixOS/nixpkgs/nixos-unstable",
        "nixos-unstable": "github:NixOS/nixpkgs/nixos-unstable",
        "nixpkgs-unstable": "github:NixOS/nixpkgs/nixpkgs-unstable",
        "pkgs-unstable": "github:NixOS/nixpkgs/nixpkgs-unstable",
        "master": "github:NixOS/nixpkgs/master",
        "staging": "github:NixOS/nixpkgs/staging",
        "staging-next": "github:NixOS/nixpkgs/staging-next",
        "cachyos": "github:xddxdd/nix-cachyos-kernel/release",
        "nix-cachyos-kernel": "github:xddxdd/nix-cachyos-kernel/release",
    }

    if val.lower() in mapping:
        return mapping[val.lower()]

    # Format XX.YY, nixos-XX.YY, nixpkgs-XX.YY (e.g. 26.05, nixpkgs-25.11, nixos-24.05)
    m = re.match(r"^(?:nixos-|nixpkgs-)?(\d{2}\.\d{2}(?:-small|-darwin)?)$", val, re.IGNORECASE)
    if m:
        sub = m.group(1)
        if sub.endswith("-darwin"):
            return f"github:NixOS/nixpkgs/nixpkgs-{sub}"
        return f"github:NixOS/nixpkgs/nixos-{sub}"

    # Check flake.lock for matching input name via root inputs mapping
    flake_dir = find_flake_dir()
    if flake_dir:
        flake_lock = flake_dir / "flake.lock"
        if flake_lock.is_file():
            try:
                data = json.loads(flake_lock.read_text(encoding="utf-8"))
                nodes = data.get("nodes", {})
                root_node = nodes.get(data.get("root", "root"), {})
                root_inputs = root_node.get("inputs", {})

                if val in root_inputs:
                    # Valid local input name in flake.lock root inputs
                    return val

                target_id = root_inputs.get(val, val)
                if target_id in nodes:
                    node_data = nodes[target_id]
                    orig = node_data.get("original", {})
                    t = orig.get("type")
                    if t == "github" and orig.get("owner") and orig.get("repo"):
                        ref = f"/{orig.get('ref')}" if orig.get("ref") else ""
                        return f"github:{orig.get('owner')}/{orig.get('repo')}{ref}"
                    elif t == "gitlab" and orig.get("owner") and orig.get("repo"):
                        ref = f"/{orig.get('ref')}" if orig.get("ref") else ""
                        return f"gitlab:{orig.get('owner')}/{orig.get('repo')}{ref}"
                    elif t == "git" and orig.get("url"):
                        url = orig.get("url", "")
                        ref = orig.get("ref", "")
                        if "github.com/" in url:
                            parts = url.split("github.com/")[-1].rstrip("/").replace(".git", "").split("/")
                            if len(parts) >= 2:
                                ref_part = f"/{ref}" if ref else ""
                                return f"github:{parts[0]}/{parts[1]}{ref_part}"
                        ref_suffix = f"?ref={ref}" if ref else ""
                        return f"git+{url}{ref_suffix}"
                    elif orig.get("url"):
                        return orig.get("url")
            except Exception:
                pass

    return val


def find_cache_pins_file(custom_path: Optional[str] = None) -> Optional[Path]:
    """Dynamically discover modules/_lib/cache-pins.nix."""
    if custom_path:
        p = Path(custom_path)
        if p.is_file():
            return p.resolve()
        return None

    # Check environment variable
    env_path = os.environ.get("PINS_FILE")
    if env_path and Path(env_path).is_file():
        return Path(env_path).resolve()

    # Search upwards from current working directory
    cwd = Path.cwd()
    for parent in [cwd] + list(cwd.parents):
        candidate = parent / "modules" / "_lib" / "cache-pins.nix"
        if candidate.is_file():
            return candidate.resolve()

    # Search standard configuration paths
    home = Path.home()
    candidates = [
        home / "nixos-config" / "modules" / "_lib" / "cache-pins.nix",
        home / ".config" / "nixos" / "modules" / "_lib" / "cache-pins.nix",
        Path("/etc/nixos/modules/_lib/cache-pins.nix"),
    ]
    for c in candidates:
        if c.is_file():
            return c.resolve()

    return None


def _get_nix_env() -> Dict[str, str]:
    """Return environment dictionary with unfree and insecure evaluation enabled."""
    env = os.environ.copy()
    env["NIXPKGS_ALLOW_UNFREE"] = "1"
    env["NIXPKGS_ALLOW_INSECURE"] = "1"
    env["NIXPKGS_ALLOW_BROKEN"] = "1"
    return env


def eval_nix_raw(expr: str, flake_input: Optional[str] = None, verbose: Optional[bool] = None) -> Optional[str]:
    """Evaluate a raw Nix expression via 'nix eval --raw' with real-time progress feedback and return trimmed string."""
    flake_dir = find_flake_dir()
    flake_prefix = f"{flake_dir}#" if flake_dir else ""

    cmd = ["nix", "eval", "--raw", "--impure"]

    if flake_input and not expr.startswith("builtins.") and not expr.startswith("import"):
        if any(flake_input.startswith(prefix) for prefix in ["github:", "gitlab:", "path:", "git+", "git:"]):
            eval_expr = f'(builtins.getFlake "{flake_input}").legacyPackages.x86_64-linux.{expr}'
        else:
            eval_expr = f'(builtins.getFlake "{flake_prefix}").inputs.{flake_input}.legacyPackages.x86_64-linux.{expr}'
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
            env=_get_nix_env(),
        )

        stdout_chunks = []

        def handle_stderr():
            for raw_line in iter(proc.stderr.readline, ""):
                if not raw_line:
                    break
                line = raw_line.strip()
                if not line:
                    continue
                if is_verbose:
                    print(f"  [nix] {line}", file=sys.stderr, flush=True)
                elif is_tty:
                    # Ambil cuplikan ringkas progress dari Nix stderr
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

        proc.wait(timeout=180)
        t_err.join(timeout=2)
        t_out.join(timeout=2)

        if is_tty and not is_verbose:
            print("\033[2K\r", file=sys.stderr, end="", flush=True)

        if proc.returncode == 0:
            return "".join(stdout_chunks).strip()
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


def extract_version_from_store_path(store_path: str) -> str:
    """Extract human-readable version from a Nix store path string."""
    base = os.path.basename(store_path)
    # Remove the 32-char hash prefix (e.g. 86nhn0hbzqww5s85573nyfw5ci1xc882-rclone-1.75.0)
    parts = base.split("-", 1)
    if len(parts) < 2:
        return "unknown"
    pkg_full_name = parts[1]
    match = re.search(r"-(\d[\w\.\-]+)$", pkg_full_name)
    if match:
        return match.group(1)
    return "pinned"


def is_path_in_nix_store(store_path: str) -> bool:
    """Check if a store path physically exists in /nix/store (zero subprocess / zero daemon connection overhead)."""
    if not store_path or not store_path.startswith("/nix/store/"):
        return False
    return os.path.exists(store_path)


def compare_versions(v1: str, v2: str) -> int:
    """Compare two version strings (SemVer, date-based, or alpha/beta).

    Returns:
         1 if v1 > v2 (v1 is newer)
         0 if v1 == v2
        -1 if v1 < v2 (v1 is older / downgrade)
    """
    if not v1 or not v2 or v1 == "unknown" or v2 == "unknown":
        return 0 if v1 == v2 else (1 if v1 and v1 != "unknown" else -1)

    if v1 == v2:
        return 0

    nums1 = [int(n) for n in re.findall(r"\d+", v1)]
    nums2 = [int(n) for n in re.findall(r"\d+", v2)]

    if nums1 and nums2:
        for n1, n2 in zip(nums1, nums2):
            if n1 > n2:
                return 1
            elif n1 < n2:
                return -1
        if len(nums1) > len(nums2):
            return 1
        elif len(nums1) < len(nums2):
            return -1

    return 1 if v1 > v2 else -1


def eval_nix_package_info(
    candidates: list,
    flake_input: str = "nixpkgs",
    verbose: Optional[bool] = None,
) -> Tuple[Optional[str], str, Optional[str]]:
    """Evaluate package store path, version, and mainProgram in a SINGLE atomic Nix eval call."""
    flake_dir = find_flake_dir()
    flake_prefix = f"{flake_dir}#" if flake_dir else ""

    if any(flake_input.startswith(prefix) for prefix in ["github:", "gitlab:", "path:", "git+", "git:"]):
        flake_target_expr = f'(builtins.getFlake "{flake_input}")'
    else:
        flake_target_expr = f'(builtins.getFlake "{flake_prefix}").inputs.{flake_input}'

    candidates_nix = " ".join(f'"{c}"' for c in candidates if c)

    expr = f"""
    let
      fl = {flake_target_expr};
      pkgs = fl.legacyPackages.x86_64-linux or fl.packages.x86_64-linux or {{}};
      candidates = [ {candidates_nix} ];

      getAttr = p: name:
        let r = builtins.tryEval (p.${{name}} or null); in if r.success then r.value else null;

      tryPkg = name:
        let
          p1 = getAttr pkgs name;
          p2 = getAttr (pkgs.python3Packages or {{}}) name;
          p3 = getAttr (pkgs.python314Packages or {{}}) name;
          p4 = getAttr (pkgs.python313Packages or {{}}) name;
          p5 = getAttr (pkgs.python312Packages or {{}}) name;
          p6 = getAttr (pkgs.linuxPackages or {{}}) name;
          found = if p1 != null then p1
                  else if p2 != null then p2
                  else if p3 != null then p3
                  else if p4 != null then p4
                  else if p5 != null then p5
                  else p6;
        in
          if found != null && (found ? outPath || builtins.isPath found) then
            let
              drv = if found ? kernel then found.kernel else found;
              v = drv.version or "unknown";
              mp = drv.meta.mainProgram or null;
              sp = builtins.unsafeDiscardStringContext (toString drv.outPath or drv);
            in
              {{
                storePath = sp;
                version = v;
                mainProgram = mp;
              }}
          else null;

      results = builtins.filter (x: x != null) (map tryPkg candidates);
    in
      if results != [] then builtins.head results else null
    """

    cmd = ["nix", "eval", "--json", "--impure", "--expr", expr]

    is_verbose = verbose if verbose is not None else (os.environ.get("NCP_VERBOSE") == "1")
    is_tty = sys.stderr.isatty()

    try:
        proc = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            bufsize=1,
            env=_get_nix_env(),
        )

        stdout_chunks = []

        def handle_stderr():
            for raw_line in iter(proc.stderr.readline, ""):
                if not raw_line:
                    break
                line = raw_line.strip()
                if not line:
                    continue
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

        proc.wait(timeout=180)
        t_err.join(timeout=2)
        t_out.join(timeout=2)

        if is_tty and not is_verbose:
            print("\033[2K\r", file=sys.stderr, end="", flush=True)

        if proc.returncode == 0:
            raw_out = "".join(stdout_chunks).strip()
            if raw_out and raw_out != "null":
                data = json.loads(raw_out)
                if isinstance(data, dict) and "storePath" in data:
                    sp = data["storePath"]
                    ver = data.get("version") or extract_version_from_store_path(sp)
                    main_prog = data.get("mainProgram")
                    return sp, ver, main_prog
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

    return None, "unknown", None


def evaluate_upstream_package(
    target_key: str,
    nixpkgs_input: str = "nixpkgs",
    pname: Optional[str] = None,
    verbose: Optional[bool] = None,
) -> Tuple[Optional[str], str, Optional[str]]:
    """Smart evaluator for upstream packages that handles pname, underscores, dashes, python packages, and flake expressions."""
    candidates = []

    if pname:
        clean_pname = pname.replace("pkgs.", "").strip()
        if clean_pname:
            candidates.append(clean_pname)
            p_dash = clean_pname.replace("_", "-")
            p_under = clean_pname.replace("-", "_")
            if p_dash not in candidates:
                candidates.append(p_dash)
            if p_under not in candidates:
                candidates.append(p_under)

    clean_key = target_key.replace("pkgs.", "")
    var_dash = clean_key.replace("_", "-")
    var_under = clean_key.replace("-", "_")

    for k in [clean_key, var_dash, var_under]:
        if k not in candidates:
            candidates.append(k)

    # Tambahkan variasi alias umum di Nixpkgs jika belum ada
    common_suffixes = [
        "-desktop",
        "-desktopeditors",
        "_desktop",
        "-bin",
        "-cli",
        "-gui",
        "-with-plugins",
    ]
    for k in list(candidates):
        for suf in common_suffixes:
            candidate_variant = f"{k}{suf}"
            if candidate_variant not in candidates:
                candidates.append(candidate_variant)

    return eval_nix_package_info(candidates, nixpkgs_input, verbose=verbose)


def resolve_target_to_store_path(
    target: str,
    nixpkgs_input: str = "nixpkgs",
    pins_file: Optional[Path] = None,
) -> Tuple[str, str, Optional[str]]:
    """Resolve a target name, attr, or store path into a validated (store_path, version, main_program) tuple."""
    # 1. Direct Store Path
    if target.startswith("/nix/store/"):
        store_path = target.rstrip("/")
        version = extract_version_from_store_path(store_path)
        return store_path, version, None

    clean_target = target.replace("pkgs.", "")
    var_dash = clean_target.replace("_", "-")
    var_under = clean_target.replace("-", "_")

    # Ambil metadata cached (seperti pname) dari pins_file jika ada
    cached_pname = None
    cached_entry = None
    if pins_file and pins_file.is_file():
        try:
            expr = f"import {pins_file}"
            res = subprocess.run(
                ["nix", "eval", "--json", "--impure", "--expr", expr],
                capture_output=True,
                text=True,
                timeout=10,
                env=_get_nix_env(),
            )
            if res.returncode == 0:
                data = json.loads(res.stdout)
                for key_candidate in [clean_target, var_dash, var_under]:
                    if key_candidate in data:
                        cached_entry = data[key_candidate]
                        if isinstance(cached_entry, dict):
                            cached_pname = cached_entry.get("pname")
                        break
        except Exception:
            pass

    # 2. Utamakan evaluasi dari channel / input yang diminta pengguna
    sp, ver, main_prog = evaluate_upstream_package(
        target_key=clean_target,
        nixpkgs_input=nixpkgs_input,
        pname=cached_pname,
    )
    if sp and sp.startswith("/nix/store/"):
        return sp, ver, main_prog

    # 3. Fallback: gunakan entri pin lokal jika evaluasi upstream gagal
    if cached_entry and isinstance(cached_entry, dict) and "storePath" in cached_entry:
        sp = cached_entry["storePath"]
        ver = cached_entry.get("version") or extract_version_from_store_path(sp)
        main_prog = cached_entry.get("mainProgram")
        return sp, ver, main_prog

    # 4. Smart recursive search in flake inputs and configs
    flake_dir = find_flake_dir()
    if flake_dir:
        flake_prefix = f"{flake_dir}#"
        smart_expr = f"""
        let
          fl = builtins.getFlake "{flake_prefix}";
          inputs = fl.inputs or {{}};
          cfgs = builtins.attrValues (fl.nixosConfigurations or {{}});

          checkPkg = p:
            if p != null && (p ? outPath || builtins.isPath p)
            then builtins.unsafeDiscardStringContext (toString p.outPath or p)
            else "";

          searchInputs = builtins.concatLists (
            builtins.map (inp:
              let
                pk = inp.legacyPackages.x86_64-linux or inp.packages.x86_64-linux or {{}};
                res = checkPkg (pk."{clean_target}" or pk."{var_dash}" or pk."{var_under}" or null);
              in
                if res != "" then [ res ] else []
            ) (builtins.attrValues inputs)
          );

          searchConfigs =
            let
              res = builtins.map (c:
                let
                  pk = c.pkgs or {{}};
                  k = c.config.boot.kernelPackages.kernel or null;
                  checkC = if "{clean_target}" == "cachyos-kernel" || "{clean_target}" == "kernel"
                           then checkPkg (pk.linuxPackages_cachyos.kernel or null)
                           else "";
                  checkK = if "{clean_target}" == "kernel" || "{clean_target}" == "boot.kernelPackages"
                           then checkPkg k
                           else "";
                  checkP = checkPkg (pk."{clean_target}" or pk."{var_dash}" or pk."{var_under}" or null);
                in
                  if checkC != "" then checkC else if checkK != "" then checkK else checkP
              ) cfgs;
            in
              builtins.filter (x: x != "") res;

          finalList = searchInputs ++ searchConfigs;
        in
          if finalList != [] then builtins.head finalList else ""
        """
        store_path = eval_nix_raw(smart_expr)
        if store_path and store_path.startswith("/nix/store/"):
            version = extract_version_from_store_path(store_path)
            return store_path, version, None

    raise RuntimeError(
        f"Tidak dapat menemukan store path untuk '{target}' pada channel/input '{nixpkgs_input}'. "
        "Pastikan nama atribut valid atau terdaftar di modules/_lib/cache-pins.nix."
    )
