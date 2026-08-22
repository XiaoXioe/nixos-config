import os
import sys
import subprocess
import tarfile
import base64
import json
import time
import re
from pathlib import Path

WORK_DIR = Path("/tmp/orig-kernel")
WORK_DIR.mkdir(parents=True, exist_ok=True)

REPO_ROOT = Path("/home/klein-moretti/nixos-config")

# Retrieve local tokens as infallible fallbacks
def get_local_github_token():
    try:
        r = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True)
        if r.returncode == 0 and r.stdout.strip():
            return r.stdout.strip()
    except Exception:
        pass
    return ""

def get_local_cachix_token():
    dhall_path = Path.home() / ".config/cachix/cachix.dhall"
    if dhall_path.exists():
        content = dhall_path.read_text()
        m = re.search(r'authToken\s*=\s*"([^"]+)"', content)
        if m:
            return m.group(1)
    return ""

local_gh_token = get_local_github_token()
local_cachix_token = get_local_cachix_token()

print(f"🔑 Local tokens found: GitHub={bool(local_gh_token)}, Cachix={bool(local_cachix_token)}")

print("📦 [1/4] Mengemas codebase lokal (termasuk staging)...")
tar_path = WORK_DIR / "codebase.tar.xz"

def filter_tar(tarinfo):
    name = tarinfo.name
    if any(x in name for x in [".git/", "result", ".direnv", "node_modules", "tmp", ".cache", ".assets"]):
        return None
    return tarinfo

with tarfile.open(tar_path, "w:xz") as tar:
    for item in REPO_ROOT.iterdir():
        if item.name in [".git", "result", ".direnv", "node_modules", "tmp", ".cache", ".assets"]:
            continue
        tar.add(item, arcname=item.name, filter=filter_tar)

print(f"  Ukuran arsip: {tar_path.stat().st_size / 1024:.1f} KB")

with open(tar_path, "rb") as f:
    codebase_b64 = base64.b64encode(f.read()).decode("utf-8")

print(f"  Ukuran payload base64: {len(codebase_b64) / 1024:.1f} KB")

print("📝 [2/4] Membuat runner script nix-remote-builder.py untuk Kaggle...")

# Pure Python Runner Script (No bash wrapping, no heredocs)
kernel_py_lines = [
    "import os, sys, subprocess, json, base64, tarfile",
    "",
    "print('=== 🚀 Starting Pure Python Nix Test Runner on Kaggle ===')",
    "",
    f"GITHUB_TOKEN = {json.dumps(local_gh_token)}",
    f"CACHIX_TOKEN = {json.dumps(local_cachix_token)}",
    "",
    "# 1. Setup Storage & Bind Mount",
    "os.makedirs('/kaggle/working/nix', exist_ok=True)",
    "os.makedirs('/nix', exist_ok=True)",
    "subprocess.run(['mount', '--bind', '/kaggle/working/nix', '/nix'], stderr=subprocess.DEVNULL)",
    "",
    "# 2. Install Determinate Nix if needed",
    "if not os.path.exists('/nix/var/nix/profiles/default/bin/nix'):",
    "    print('Installing Determinate Nix...')",
    "    subprocess.run('curl --proto =https --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install linux --init none --no-confirm', shell=True, check=True)",
    "",
    "os.environ['PATH'] = f'/nix/var/nix/profiles/default/bin:{os.environ[\"PATH\"]}'",
    "os.environ['NIXPKGS_ALLOW_UNFREE'] = '1'",
    "if GITHUB_TOKEN:",
    "    os.environ['NIX_CONFIG'] = f'access-tokens = github.com={GITHUB_TOKEN}'",
    "",
    "# Setup nix.conf",
    "nix_conf = f'''experimental-features = nix-command flakes",
    "max-jobs = auto",
    "cores = 0",
    "trusted-users = root kaggle",
    "substituters = https://cache.nixos.org https://cachixix.cachix.org https://cache.tvl.su",
    "trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= cachixix.cachix.org-1:gxuKepBrK+XUD1RpGPCg0pyZZrxKayVWiugCfDJebLc= tvl.su-1:HQXlqAnqOfSpJcqrmqFmljOexiuzQ7KogF9QpHhE290=",
    "access-tokens = github.com={GITHUB_TOKEN}",
    "'''",
    "os.makedirs('/root/.config/nix', exist_ok=True)",
    "os.makedirs('/etc/nix', exist_ok=True)",
    "with open('/root/.config/nix/nix.conf', 'w') as f: f.write(nix_conf)",
    "with open('/etc/nix/nix.conf', 'w') as f: f.write(nix_conf)",
    "",
    "# 3. Extract Codebase",
    "src_dir = '/kaggle/working/src'",
    "os.makedirs(src_dir, exist_ok=True)",
    "os.chdir(src_dir)",
    f"CODEBASE_B64 = {json.dumps(codebase_b64)}",
    "with open('/tmp/codebase.tar.xz', 'wb') as f: f.write(base64.b64decode(CODEBASE_B64))",
    "subprocess.run(['tar', '-xJf', '/tmp/codebase.tar.xz'], check=True)",
    "subprocess.run(['git', 'init'])",
    "subprocess.run(['git', 'config', 'user.name', 'CI Tester'])",
    "subprocess.run(['git', 'config', 'user.email', 'ci@tester.local'])",
    "subprocess.run(['git', 'add', '-A'])",
    "",
    "# 4. Test 1: Evaluasi Toplevel",
    "print('\\n--- [Test 1] Evaluasi Toplevel NixOS Host KleinMoretti ---')",
    "auth_opt = ['--option', 'access-tokens', f'github.com={GITHUB_TOKEN}'] if GITHUB_TOKEN else []",
    "eval_res = subprocess.run(['nix', 'eval', '.#nixosConfigurations.KleinMoretti.config.system.build.toplevel.drvPath', '--show-trace', '--impure'] + auth_opt)",
    "if eval_res.returncode != 0:",
    "    print('❌ Evaluasi toplevel gagal!')",
    "    sys.exit(1)",
    "print('✅ Evaluasi toplevel berhasil!')",
    "",
    "# 5. Test 2: Evaluasi & Build 28 Native Apps",
    "print('\\n--- [Test 2] Testing Build All Native Packages ---')",
    "expr = '''let",
    "  flake = builtins.getFlake (toString ./.);",
    "  host = flake.nixosConfigurations.KleinMoretti;",
    "  pkgs = host.pkgs;",
    "  selfLib = flake.outputs.selfLib or (import ./modules/_lib { inherit (pkgs) lib; inherit pkgs; });",
    "  hPkgs = host.config.home-manager.users.klein-moretti.home.packages;",
    "  sysPkgs = host.config.environment.systemPackages;",
    "  allPkgs = hPkgs ++ sysPkgs;",
    "  findDrv = name:",
    "    let",
    "      matches = builtins.filter (p: (p.pname or \"\") == name || (p.name or \"\") == name || (builtins.substring 0 (builtins.stringLength name) (p.pname or (p.name or \"\"))) == name) allPkgs;",
    "    in",
    "      if matches != [] then (builtins.head matches).drvPath",
    "      else if name == \"zed\" then host.config.home-manager.users.klein-moretti.programs.zed-editor.package.drvPath",
    "      else (selfLib.fetchApp pkgs name).drvPath;",
    "in",
    "  builtins.listToAttrs (builtins.map (name: { inherit name; value = findDrv name; }) [",
    "    \"brave\" \"chromium\" \"firefox\" \"librewolf\" \"tor-browser\"",
    "    \"discord\" \"signal-desktop\" \"materialgram\" \"obsidian\" \"onlyoffice-desktopeditors\"",
    "    \"betterbird\" \"tradingview\" \"codium\" \"zed\" \"bitwarden\"",
    "    \"proton-pass\" \"ente-auth\" \"dolphin-emu\" \"ppsspp\" \"pcsx2\"",
    "    \"retroarch\" \"wine\" \"gthumb\" \"zathura\" \"yt-dlp\"",
    "    \"gallery-dl\" \"aria2\" \"tdl\"",
    "  ])'''",
    "",
    "eval_apps_res = subprocess.run(['nix', 'eval', '--json', '--impure', '--expr', expr] + auth_opt, capture_output=True, text=True)",
    "if eval_apps_res.returncode != 0:",
    "    print('❌ Gagal evaluasi derivasi aplikasi:', eval_apps_res.stderr)",
    "    sys.exit(1)",
    "",
    "apps_dict = json.loads(eval_apps_res.stdout)",
    "passed = 0",
    "failed = 0",
    "failed_apps = []",
    "",
    "for name, drv in apps_dict.items():",
    "    print(f'\\n==========================================================')",
    "    print(f' 🔍 Testing Native Package: {name}')",
    "    print(f' Derivation: {drv}')",
    "    print(f'==========================================================')",
    "    b_res = subprocess.run(['nix', 'build', drv, '--no-link', '-L', '--impure'] + auth_opt)",
    "    if b_res.returncode == 0:",
    "        print(f'  ✅ SUCCESS: {name}')",
    "        passed += 1",
    "    else:",
    "        print(f'  ❌ FAILED: {name}')",
    "        failed += 1",
    "        failed_apps.append(name)",
    "",
    "# 6. Test 3: Build Full NixOS Toplevel",
    "print('\\n--- [Test 3] Testing Build Full NixOS Toplevel ---')",
    "top_res = subprocess.run(['nix', 'build', '.#nixosConfigurations.KleinMoretti.config.system.build.toplevel', '--no-link', '-L', '--impure'] + auth_opt)",
    "",
    "# 7. Push to Cachix",
    "if CACHIX_TOKEN:",
    "    print('\\n=== Caching to Cachix ===')",
    "    subprocess.run(['nix', 'run', 'github:NixOS/nixpkgs/nixos-26.05#cachix', '--', 'authtoken', CACHIX_TOKEN])",
    "    info_res = subprocess.run(['nix', 'path-info', '.#nixosConfigurations.KleinMoretti.config.system.build.toplevel', '--impure'] + auth_opt, capture_output=True, text=True)",
    "    if info_res.returncode == 0:",
    "        subprocess.run(['nix', 'run', 'github:NixOS/nixpkgs/nixos-26.05#cachix', '--', 'push', 'cachixix'], input=info_res.stdout, text=True)",
    "",
    "print('\\n==========================================================')",
    "print(' 📊 FINAL SUMMARY')",
    "print('==========================================================')",
    "print(f' Total Apps Tested : {len(apps_dict)}')",
    "print(f' Passed            : {passed}')",
    "print(f' Failed            : {failed}')",
    "if failed > 0 or top_res.returncode != 0:",
    "    print(f' Failed Apps       : {failed_apps}')",
    "    sys.exit(1)",
    "",
    "print(' 🎉 ALL 28 NATIVE APPS & NIXOS TOPLEVEL PASSED IN KAGGLE!')",
    "sys.exit(0)",
]

kernel_py_content = "\n".join(kernel_py_lines)

with open(WORK_DIR / "nix-remote-builder.py", "w", encoding="utf-8") as f:
    f.write(kernel_py_content)

metadata = {
    "id": "akbarnasuha/nix-remote-builder",
    "id_no": 129148259,
    "title": "Nix Remote Builder",
    "code_file": "nix-remote-builder.py",
    "language": "python",
    "kernel_type": "script",
    "is_private": True,
    "enable_gpu": False,
    "enable_tpu": False,
    "enable_internet": True,
    "keywords": [],
    "dataset_sources": [
        "akbarnasuha/nixos-builder-secrets"
    ],
    "kernel_sources": [],
    "competition_sources": [],
    "model_sources": [],
    "docker_image": "gcr.io/kaggle-images/python@sha256:dafd4ce5668bbf1ad422e4c109e0f18c9623c3a7c7f48b0235f13142755c40b9",
    "machine_shape": "None"
}

with open(WORK_DIR / "kernel-metadata.json", "w", encoding="utf-8") as f:
    json.dump(metadata, f, indent=2)

print("🚀 [3/4] Mengunggah kernel ke Kaggle (kaggle kernels push)...")
push_res = subprocess.run(["kaggle", "kernels", "push", "-p", str(WORK_DIR)], capture_output=True, text=True)
print(push_res.stdout)
if push_res.returncode != 0:
    print("Error pushing to Kaggle:", push_res.stderr)
    sys.exit(1)

print("⏳ [4/4] Kernel berhasil diunggah!")
