"""Package version searcher via NixHub and Nixpkgs release references with interactive FZF picker."""
import os
from pathlib import Path
import re
import subprocess
import sys
from typing import Any, Dict, List, Optional
import urllib.error
import urllib.request

_scripts_dir = str(Path(__file__).resolve().parent)
if _scripts_dir not in sys.path:
    sys.path.insert(0, _scripts_dir)


def fetch_package_versions(pkg_name: str) -> List[Dict[str, str]]:
    """Fetch package version history from NixHub."""
    clean_pkg = pkg_name.replace("pkgs.", "").strip()
    url = f"https://www.nixhub.io/packages/{clean_pkg}"
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 (X11; Linux x86_64)"})

    results: List[Dict[str, str]] = []

    try:
        with urllib.request.urlopen(req, timeout=8) as r:
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
            date = date_match.group(1) if date_match else "unknown"

            results.append(
                {
                    "version": version,
                    "commit": commit,
                    "attr": attr.strip(),
                    "date": date,
                    "flake_input": f"github:NixOS/nixpkgs/{commit}",
                }
            )
    except Exception as e:
        print(f"⚠️ Warning: Gagal mengambil riwayat dari NixHub ({e})", file=sys.stderr)

    # Standard channels as fallback/complement
    standard_channels = [
        ("unstable", "nixos-unstable", "github:NixOS/nixpkgs/nixos-unstable"),
        ("26.05", "nixos-26.05", "github:NixOS/nixpkgs/nixos-26.05"),
        ("25.11", "nixos-25.11", "github:NixOS/nixpkgs/nixos-25.11"),
        ("24.11", "nixos-24.11", "github:NixOS/nixpkgs/nixos-24.11"),
    ]

    for label, branch, flake_url in standard_channels:
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


def interactive_version_picker(pkg_name: str) -> Optional[Dict[str, str]]:
    """Open an interactive FZF menu allowing user to select a specific package version."""
    clean_pkg = pkg_name.replace("pkgs.", "").strip()

    which_fzf = subprocess.run(["which", "fzf"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    if which_fzf.returncode != 0:
        print("❌ ERROR: 'fzf' tidak ditemukan di sistem Anda.", file=sys.stderr)
        sys.exit(1)

    print(f"🔍 Mengambil riwayat rilis untuk '{clean_pkg}'...", file=sys.stderr)
    versions = fetch_package_versions(clean_pkg)

    if not versions:
        print(f"❌ ERROR: Tidak ditemukan riwayat versi untuk '{clean_pkg}'", file=sys.stderr)
        return None

    rows: List[str] = []
    for item in versions:
        v = item["version"]
        commit_short = item["commit"][:10] if len(item["commit"]) >= 10 else item["commit"]
        d = item["date"]
        flake_in = item["flake_input"]
        row = f"v{v:<15}  |  {d:<18}  |  {commit_short:<12}  |  {flake_in}"
        rows.append(row)

    input_text = "\n".join(rows)

    query_script = str(Path(_scripts_dir) / "query_pin.py")
    # Preview evaluates the package with the specific flake input in column 7
    preview_cmd = f"python3 {query_script} pkgs.{clean_pkg} --input {{7}}"

    fzf_cmd = [
        "fzf",
        "--ansi",
        f"--prompt=📦 Pilih Versi {clean_pkg} > ",
        "--header=Navigasi: ↑↓ | Pilih Versi: ENTER | Batal: Esc/Ctrl-C",
        f"--preview={preview_cmd}",
        "--preview-window=right:55%:wrap",
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
    selected_version_str = selected_line.split()[0].lstrip("v")
    selected_flake_input = selected_line.split()[-1]

    for item in versions:
        if item["version"] == selected_version_str or item["flake_input"] == selected_flake_input:
            return item

    return {
        "version": selected_version_str,
        "commit": selected_flake_input.split("/")[-1],
        "attr": clean_pkg,
        "date": "selected",
        "flake_input": selected_flake_input,
    }
