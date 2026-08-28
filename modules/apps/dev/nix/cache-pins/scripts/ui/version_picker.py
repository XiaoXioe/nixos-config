"""Package version searcher via NixHub, local Flake inputs, Git release tags, and Nixpkgs channels."""
import json
import os
from pathlib import Path
import re
import subprocess
import sys
from typing import Any, Dict, List, Optional, Tuple
import urllib.error
import urllib.request

from core.nix_eval import find_flake_dir, get_current_system


def fetch_git_tags(repo_url: str) -> List[Tuple[str, str]]:
    """Fetch git release tags and commits using git ls-remote."""
    tags: List[Tuple[str, str]] = []
    try:
        clean_url = repo_url
        if clean_url.startswith("github:"):
            parts = clean_url.replace("github:", "").split("/")
            clean_url = f"https://github.com/{parts[0]}/{parts[1]}"
        elif clean_url.startswith("gitlab:"):
            parts = clean_url.replace("gitlab:", "").split("/")
            clean_url = f"https://gitlab.com/{parts[0]}/{parts[1]}"

        res = subprocess.run(
            ["git", "ls-remote", "--tags", "--refs", clean_url],
            capture_output=True,
            text=True,
            timeout=8,
        )
        if res.returncode == 0:
            for line in res.stdout.splitlines():
                parts = line.strip().split()
                if len(parts) >= 2:
                    commit, ref = parts[0], parts[1]
                    tag = ref.replace("refs/tags/", "")
                    if "^{}" not in tag:
                        tags.append((tag, commit))
    except Exception:
        pass

    def version_sort_key(item):
        tag = item[0]
        nums = [int(n) for n in re.findall(r"\d+", tag)]
        is_release = 1 if not any(p in tag.lower() for p in ["alpha", "beta", "rc", "pre"]) else 0
        return (nums, is_release, tag)

    try:
        tags.sort(key=version_sort_key, reverse=True)
    except Exception:
        tags.reverse()

    return tags


def fetch_flake_package_variants(
    clean_pkg: str,
    matching_input_names: List[str],
    flake_dir: Path,
    system: Optional[str] = None,
) -> List[Dict[str, str]]:
    """Discover all package attributes and versions exported by matching flake inputs."""
    target_system = system or get_current_system()
    all_results: List[Dict[str, str]] = []

    for input_name in matching_input_names:
        if input_name in ["nixpkgs", "home-manager", "git-hooks"]:
            continue
        expr = f"""
        let
          f = builtins.getFlake (toString {flake_dir});
          system = "{target_system}";
          lib = f.inputs.nixpkgs.lib or (import <nixpkgs> {{}}).lib;
          inp = f.inputs."{input_name}" or {{}};
          pkgs = inp.packages.${{system}} or {{}};
          legPkgs = inp.legacyPackages.${{system}} or {{}};
          allNames = builtins.attrNames pkgs ++ builtins.attrNames legPkgs;
          getInfo = attrName:
            let
              p = pkgs.${{attrName}} or legPkgs.${{attrName}} or null;
              isPkgSet = p != null && p ? kernel;
              drv = if isPkgSet then p.kernel else p;
              v = if drv != null && drv ? version then drv.version else "unknown";
            in
              if drv != null && drv ? outPath then {{
                inherit attrName;
                version = v;
              }} else null;
        in
          map getInfo (lib.unique allNames)
        """
        try:
            nix_env = os.environ.copy()
            nix_env["NIXPKGS_ALLOW_UNFREE"] = "1"
            nix_env["NIXPKGS_ALLOW_INSECURE"] = "1"
            res = subprocess.run(
                ["nix", "eval", "--json", "--impure", "--expr", expr],
                capture_output=True,
                text=True,
                timeout=10,
                env=nix_env,
            )
            if res.returncode == 0:
                data = json.loads(res.stdout)
                for item in data:
                    if item:
                        item["inputName"] = input_name
                        all_results.append(item)
        except Exception:
            pass

    return all_results


def fetch_package_versions(pkg_name: str, system: Optional[str] = None) -> List[Dict[str, str]]:
    """Fetch package version history from local flake inputs, Git tags, NixHub, and standard channels."""
    clean_pkg = pkg_name.replace("pkgs.", "").strip()
    target_system = system or get_current_system()
    results: List[Dict[str, str]] = []
    seen_attrs = set()

    # 1. Check local flake inputs, package variants, & Git tags from flake.lock
    flake_dir = find_flake_dir()
    if flake_dir:
        flake_lock = flake_dir / "flake.lock"
        if flake_lock.is_file():
            try:
                data = json.loads(flake_lock.read_text(encoding="utf-8"))
                nodes = data.get("nodes", {})
                norm_target = clean_pkg.lower().replace("-", "").replace("_", "")

                matching_nodes = []
                for name, node in nodes.items():
                    if name == "root":
                        continue
                    norm_name = name.lower().replace("-", "").replace("_", "")
                    if norm_target in norm_name or norm_name in norm_target:
                        matching_nodes.append((name, node))

                matching_input_names = [name for name, _ in matching_nodes]

                # 1.1 Discover variants
                variants = fetch_flake_package_variants(clean_pkg, matching_input_names, flake_dir, system=target_system)
                for var in variants:
                    attr = var["attrName"]
                    input_name = var["inputName"]
                    node = nodes.get(input_name, {})
                    orig = node.get("original", {})
                    locked = node.get("locked", {})
                    t = orig.get("type")
                    owner = orig.get("owner", locked.get("owner", ""))
                    repo = orig.get("repo", locked.get("repo", ""))
                    locked_rev = locked.get("rev", "")
                    ref = orig.get("ref", "locked")

                    base_url = None
                    if t == "github" and owner and repo:
                        base_url = f"github:{owner}/{repo}"
                    elif t == "gitlab" and owner and repo:
                        base_url = f"gitlab:{owner}/{repo}"

                    lock_flake_url = (
                        f"{base_url}/{locked_rev}"
                        if (base_url and locked_rev)
                        else (f"{base_url}/{ref}" if base_url else input_name)
                    )
                    unique_key = (attr, lock_flake_url)
                    if unique_key not in seen_attrs:
                        seen_attrs.add(unique_key)
                        results.append(
                            {
                                "version": var["version"],
                                "commit": (locked_rev[:10] if locked_rev else ref),
                                "attr": attr,
                                "date": f"Flake ({input_name})",
                                "flake_input": lock_flake_url,
                            }
                        )

                # 1.2 Remote Git Release Tags
                for name, node in matching_nodes:
                    orig = node.get("original", {})
                    locked = node.get("locked", {})
                    t = orig.get("type")
                    ref = orig.get("ref", "locked")
                    locked_rev = locked.get("rev", "")
                    owner = orig.get("owner", locked.get("owner", ""))
                    repo = orig.get("repo", locked.get("repo", ""))

                    base_url = None
                    if t == "github" and owner and repo:
                        base_url = f"github:{owner}/{repo}"
                    elif t == "gitlab" and owner and repo:
                        base_url = f"gitlab:{owner}/{repo}"

                    if base_url:
                        git_tags = fetch_git_tags(base_url)
                        for tag, commit in git_tags:
                            tag_flake_url = f"{base_url}/{tag}"
                            unique_key = (clean_pkg, tag_flake_url)
                            if unique_key not in seen_attrs:
                                seen_attrs.add(unique_key)
                                results.append(
                                    {
                                        "version": tag,
                                        "commit": commit[:10],
                                        "attr": clean_pkg,
                                        "date": f"Git Tag ({name})",
                                        "flake_input": tag_flake_url,
                                    }
                                )

                        if not variants and not git_tags:
                            lock_flake_url = (
                                f"{base_url}/{locked_rev}" if locked_rev else f"{base_url}/{ref}"
                            )
                            unique_key = (clean_pkg, lock_flake_url)
                            if unique_key not in seen_attrs:
                                seen_attrs.add(unique_key)
                                results.append(
                                    {
                                        "version": f"flake:{ref}",
                                        "commit": (locked_rev[:10] if locked_rev else ref),
                                        "attr": clean_pkg,
                                        "date": f"Flake ({name}: Lock)",
                                        "flake_input": lock_flake_url,
                                    }
                                )
            except Exception:
                pass

    # 2. NixHub (official Nixpkgs releases)
    url = f"https://www.nixhub.io/packages/{clean_pkg}"
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 (X11; Linux x86_64)"})

    try:
        with urllib.request.urlopen(req, timeout=6) as r:
            html = r.read().decode("utf-8")

        pattern = re.compile(
            r'<li id="([^"]+)"[^>]*>.*?class="break-all line-clamp-1">([a-f0-9]{40})</span><span[^>]*>#</span>([^<]+)',
            re.DOTALL,
        )

        seen_versions = set()
        for match in pattern.finditer(html):
            version, commit, attr = match.groups()
            if version in seen_versions:
                continue
            seen_versions.add(version)

            sub_html = html[match.start() : match.start() + 1500]
            date_match = re.search(r"Updated on ([A-Za-z]+ \d+, \d{4})", sub_html)
            date = date_match.group(1) if date_match else "Nixpkgs Hub"
            flake_url = f"github:NixOS/nixpkgs/{commit}"

            unique_key = (attr.strip(), flake_url)
            if unique_key not in seen_attrs:
                seen_attrs.add(unique_key)
                results.append(
                    {
                        "version": version,
                        "commit": commit[:10],
                        "attr": attr.strip(),
                        "date": date,
                        "flake_input": flake_url,
                    }
                )
    except Exception:
        pass

    # 3. Standard release channels
    standard_channels = [
        ("unstable", "nixos-unstable", "github:NixOS/nixpkgs/nixos-unstable"),
        ("26.05", "nixos-26.05", "github:NixOS/nixpkgs/nixos-26.05"),
        ("25.11", "nixos-25.11", "github:NixOS/nixpkgs/nixos-25.11"),
        ("24.11", "nixos-24.11", "github:NixOS/nixpkgs/nixos-24.11"),
    ]

    for label, branch, flake_url in standard_channels:
        unique_key = (clean_pkg, flake_url)
        if unique_key not in seen_attrs:
            seen_attrs.add(unique_key)
            results.append(
                {
                    "version": f"channel:{label}",
                    "commit": branch,
                    "attr": clean_pkg,
                    "date": f"NixOS {branch}",
                    "flake_input": flake_url,
                }
            )

    return results


def interactive_version_picker(
    pkg_name: str,
    cache_url: Optional[str] = None,
    system: Optional[str] = None,
) -> Optional[Dict[str, str]]:
    """Open an interactive FZF menu allowing user to select a specific package version."""
    clean_pkg = pkg_name.replace("pkgs.", "").strip()

    which_fzf = subprocess.run(["which", "fzf"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    if which_fzf.returncode != 0:
        print("❌ ERROR: 'fzf' tidak ditemukan di sistem Anda.", file=sys.stderr)
        sys.exit(1)

    print(f"🔍 Mengambil riwayat rilis untuk '{clean_pkg}'...", file=sys.stderr)
    versions = fetch_package_versions(clean_pkg, system=system)

    if not versions:
        print(f"❌ ERROR: Tidak ditemukan riwayat versi untuk '{clean_pkg}'", file=sys.stderr)
        return None

    rows: List[str] = []
    for item in versions:
        v = item["version"]
        if v.startswith("channel:") or v.startswith("flake:"):
            v_fmt = v
        else:
            v_fmt = f"v{v}" if not v.startswith("v") else v
        d = item["date"]
        attr_name = item["attr"]
        flake_in = item["flake_input"]
        row = f"{v_fmt:<20}  |  {d:<24}  |  {attr_name:<36}  |  {flake_in}"
        rows.append(row)

    input_text = "\n".join(rows)

    preview_cmd = (
        'echo -e "\\033[1;36m===================================================\\033[0m\\n'
        '\\033[1;32m📦 Paket Target :\\033[0m {3}\\n'
        '\\033[1;33m🏷️  Versi Rilis  :\\033[0m {1}\\n'
        '\\033[1;34m📅 Tanggal/Info :\\033[0m {2}\\n'
        '\\033[1;35m🌐 Flake Input  :\\033[0m {4}\\n'
        '\\033[1;36m===================================================\\033[0m\\n\\n'
        '\\033[90m💡 Tekan [ENTER] untuk memilih versi ini.\\n'
        '   ncp akan mengevaluasi store path, closure size,\\n'
        '   dan membuat snippet konfigurasi Nix.\\033[0m"'
    )

    fzf_cmd = [
        "fzf",
        "--ansi",
        "--delimiter=\\|",
        f"--prompt=📦 Pilih Versi {clean_pkg} > ",
        "--header=Navigasi: ↑↓ | Pilih Versi: ENTER | Batal: Esc/Ctrl-C",
        f"--preview={preview_cmd}",
        "--preview-window=right:50%:wrap",
        "--layout=reverse",
        "--height=85%",
        "--border",
    ]

    try:
        proc = subprocess.run(fzf_cmd, input=input_text, text=True, capture_output=True)
    except KeyboardInterrupt:
        return None

    if proc.returncode != 0 or not proc.stdout.strip():
        return None

    selected_line = proc.stdout.strip()
    parts = [p.strip() for p in selected_line.split("|")]

    if len(parts) >= 4:
        sel_ver = parts[0].lstrip("v")
        sel_attr = parts[2]
        sel_url = parts[3]
        for item in versions:
            if item["attr"] == sel_attr and item["flake_input"] == sel_url:
                return item

    selected_version_str = selected_line.split()[0].lstrip("v")
    selected_flake_input = selected_line.split()[-1]

    for item in versions:
        if item["flake_input"] == selected_flake_input or item["version"] == selected_version_str:
            return item

    return {
        "version": selected_version_str,
        "commit": selected_flake_input.split("/")[-1],
        "attr": clean_pkg,
        "date": "selected",
        "flake_input": selected_flake_input,
    }
