{
  pkgs,
  selfLib,
  ...
}:

let
  pythonEnv = pkgs.python3.withPackages (
    ps: with ps; [
      urllib3
    ]
  );

  updateScript = pkgs.writeScriptBin "update-native-apps" ''
    #!${pythonEnv}/bin/python3
    import sys
    import os
    import re
    import json
    import subprocess
    import urllib.request
    from pathlib import Path

    CONFIG_FILE = Path("modules/_lib/apps-versions.nix")

    # Helper untuk sorting versi secara alami (natural numeric sort)
    def natural_sort_key(s):
        return [int(c) if c.isdigit() else c.lower() for c in re.split(r'(\d+)', str(s))]

    # Metadata sumber rilis upstream untuk setiap aplikasi
    APP_SOURCES = {
        "brave": {
            "type": "github",
            "repo": "brave/brave-browser",
            "url_pattern": "https://github.com/brave/brave-browser/releases/download/v{version}/brave-browser_{version}_amd64.deb"
        },
        "chromium": {
            "type": "github",
            "repo": "ungoogled-software/ungoogled-chromium-binaries",
            "tag_filter": lambda t: t.replace("-1", "") if "-1" in t and not t.startswith("55.") else None,
            "url_pattern": "https://github.com/ungoogled-software/ungoogled-chromium-binaries/releases/download/{version}-1/ungoogled-chromium_{version}-1.1_linux.tar.xz"
        },
        "vscodium": {
            "type": "github",
            "repo": "VSCodium/vscodium",
            "url_pattern": "https://github.com/VSCodium/vscodium/releases/download/{version}/codium_{version}_amd64.deb"
        },
        "zed": {
            "type": "github",
            "repo": "zed-industries/zed",
            "url_pattern": "https://github.com/zed-industries/zed/releases/download/v{version}/zed-linux-x86_64.tar.gz"
        },
        "obsidian": {
            "type": "github",
            "repo": "obsidianmd/obsidian-releases",
            "url_pattern": "https://github.com/obsidianmd/obsidian-releases/releases/download/v{version}/obsidian_{version}_amd64.deb"
        },
        "onlyoffice": {
            "type": "github",
            "repo": "ONLYOFFICE/DesktopEditors",
            "url_pattern": "https://github.com/ONLYOFFICE/DesktopEditors/releases/download/v{version}/onlyoffice-desktopeditors_amd64.deb"
        },
        "bitwarden": {
            "type": "github",
            "repo": "bitwarden/clients",
            "tag_filter": lambda t: t.replace("desktop-v", "").replace("v", "") if "desktop-v" in t else None,
            "url_pattern": "https://github.com/bitwarden/clients/releases/download/desktop-v{version}/Bitwarden-{version}-amd64.deb"
        },
        "ente-auth": {
            "type": "github",
            "repo": "ente-io/ente",
            "tag_filter": lambda t: t.replace("auth-v", "").replace("v", "") if "auth-v" in t else None,
            "url_pattern": "https://github.com/ente-io/ente/releases/download/auth-v{version}/ente-auth-v{version}-x86_64.deb"
        },
        "materialgram": {
            "type": "github",
            "repo": "kukuruzka165/materialgram",
            "url_pattern": "https://github.com/kukuruzka165/materialgram/releases/download/v{version}/materialgram-v{version}.tar.zst"
        },
        "ppsspp": {
            "type": "github",
            "repo": "hrydgard/ppsspp",
            "url_pattern": "https://github.com/hrydgard/ppsspp/releases/download/v{version}/PPSSPP-v{version}-anylinux-x86_64.AppImage"
        },
        "pcsx2": {
            "type": "github",
            "repo": "PCSX2/pcsx2",
            "url_pattern": "https://github.com/PCSX2/pcsx2/releases/download/v{version}/pcsx2-v{version}-linux-appimage-x64-Qt.AppImage"
        },
        "wine": {
            "type": "github",
            "repo": "kron4ek/Wine-Builds",
            "url_pattern": "https://github.com/kron4ek/Wine-Builds/releases/download/{version}/wine-{version}-staging-amd64-wow64.tar.xz"
        },
        "yt-dlp": {
            "type": "github",
            "repo": "yt-dlp/yt-dlp",
            "url_pattern": "https://github.com/yt-dlp/yt-dlp/releases/download/{version}/yt-dlp_linux"
        },
        "gallery-dl": {
            "type": "github",
            "repo": "mikf/gallery-dl",
            "url_pattern": "https://github.com/mikf/gallery-dl/releases/download/v{version}/gallery-dl.bin"
        },
        "tdl": {
            "type": "github",
            "repo": "iyear/tdl",
            "url_pattern": "https://github.com/iyear/tdl/releases/download/v{version}/tdl_Linux_64bit.tar.gz"
        },
        "gthumb": {
            "type": "debian",
            "pkg": "gthumb",
            "url_template": "http://ftp.debian.org/debian/pool/main/g/gthumb/"
        },
        "dolphin-emu": {
            "type": "debian",
            "pkg": "dolphin-emu",
            "url_template": "http://ftp.debian.org/debian/pool/main/d/dolphin-emu/"
        },
        "zathura": {
            "type": "debian",
            "pkg": "zathura",
            "url_template": "http://ftp.debian.org/debian/pool/main/z/zathura/"
        },
        "aria2": {
            "type": "debian",
            "pkg": "aria2",
            "url_template": "http://ftp.debian.org/debian/pool/main/a/aria2/"
        },
        "retroarch": {
            "type": "libretro",
            "url_pattern": "https://buildbot.libretro.com/stable/{version}/linux/x86_64/RetroArch.7z"
        },
        "retroarch-cores": {
            "type": "libretro",
            "url_pattern": "https://buildbot.libretro.com/stable/{version}/linux/x86_64/RetroArch_cores.7z"
        }
    }

    def run_cmd(cmd):
        res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        return res.stdout.strip(), res.returncode

    def get_current_versions():
        if not CONFIG_FILE.exists():
            print(f"Error: {CONFIG_FILE} tidak ditemukan. Pastikan dijalankan dari root repositori.")
            sys.exit(1)
        
        content = CONFIG_FILE.read_text()
        versions = {}
        # Parse format: app_name = rec {\n version = "...";
        pattern = re.compile(r'(\S+)\s*=\s*rec\s*\{[^}]*version\s*=\s*"([^"]+)"', re.MULTILINE)
        for match in pattern.finditer(content):
            versions[match.group(1)] = match.group(2)
        return versions

    def get_latest_github_version(repo, tag_filter=None):
        out, code = run_cmd(f"gh release list --repo {repo} --limit 20 --json tagName --jq '.[].tagName'")
        if code != 0 or not out:
            out, code = run_cmd(f"gh release view --repo {repo} --json tagName --jq '.tagName'")
            if code != 0 or not out:
                return None
            tags = [out]
        else:
            tags = out.splitlines()

        for tag in tags:
            tag = tag.strip()
            if tag_filter:
                v = tag_filter(tag)
                if v:
                    return v
            else:
                return tag.lstrip("v")
        return None

    def get_latest_debian_package(pkg, base_url):
        try:
            req = urllib.request.Request(base_url, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req, timeout=10) as response:
                html = response.read().decode('utf-8')
            matches = re.findall(rf'{pkg}_([0-9][^"\'\s]*amd64\.deb)', html)
            if not matches:
                return None, None
            # Sort natural version
            sorted_debs = sorted(set(matches), key=natural_sort_key)
            latest_deb = sorted_debs[-1]
            
            # Ekstrak versi utama
            version_match = re.match(rf'{pkg}_([0-9]+\.[0-9]+(?:\.[0-9]+)?).*amd64\.deb', latest_deb)
            version = version_match.group(1) if version_match else latest_deb.replace(".deb", "")
            full_url = base_url + f"{pkg}_" + latest_deb
            return version, full_url
        except Exception as e:
            return None, None

    def get_latest_libretro_version():
        try:
            req = urllib.request.Request("https://buildbot.libretro.com/stable/", headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req, timeout=10) as response:
                html = response.read().decode('utf-8')
            versions = re.findall(r'([0-9]+\.[0-9]+\.[0-9]+)', html)
            if versions:
                sorted_v = sorted(set(versions), key=natural_sort_key)
                return sorted_v[-1]
        except Exception:
            pass
        return None

    def compute_sri_hash(url):
        print(f"  ⬇️  Mengunduh & menghitung hash untuk: {url}")
        out, code = run_cmd(f"nix-prefetch-url '{url}'")
        if code != 0 or not out:
            return None
        base32_hash = out.splitlines()[-1].strip()
        sri_out, code = run_cmd(f"nix hash convert --to sri --hash-algo sha256 '{base32_hash}'")
        if code != 0 or not sri_out:
            return None
        return sri_out.strip()

    def update_app_in_file(app_name, new_version, new_hash, new_url=None):
        content = CONFIG_FILE.read_text()
        
        # Cari blok aplikasi: app_name = rec { ... };
        block_pattern = re.compile(rf'({app_name}\s*=\s*rec\s*\{{)([^}}]+)(\}};)', re.MULTILINE)
        match = block_pattern.search(content)
        if not match:
            print(f"Error: Blok untuk {app_name} tidak ditemukan di {CONFIG_FILE}")
            return False

        header, body, footer = match.groups()
        
        # Ganti version
        body = re.sub(r'version\s*=\s*"[^"]+";', f'version = "{new_version}";', body)
        # Ganti hash
        body = re.sub(r'hash\s*=\s*"[^"]+";', f'hash = "{new_hash}";', body)
        # Ganti url jika ada
        if new_url:
            deb_filename = new_url.split('/')[-1]
            deb_formatted = deb_filename.replace(new_version, "''${version}")
            base_dir = "/".join(new_url.split('/')[:-1]) + "/"
            formatted_url = base_dir + deb_formatted
            body = re.sub(r'url\s*=\s*"[^"]+";', f'url = "{formatted_url}";', body)

        new_content = content[:match.start()] + header + body + footer + content[match.end():]
        CONFIG_FILE.write_text(new_content)
        run_cmd(f"nixfmt {CONFIG_FILE}")
        return True

    def main():
        args = sys.argv[1:]
        current_versions = get_current_versions()
        
        check_only = "--check" in args or "-c" in args
        target_app = [a for a in args if not a.startswith("-")]

        print("🔍 Memeriksa pembaruan upstream untuk aplikasi native...")
        apps_to_check = target_app if target_app else list(APP_SOURCES.keys())

        updates = []
        for app in apps_to_check:
            if app not in APP_SOURCES:
                print(f"⚠️  Aplikasi '{app}' tidak terdaftar di auto-updater metadata.")
                continue

            curr_v = current_versions.get(app, "unknown")
            src_info = APP_SOURCES[app]
            latest_v = None
            custom_url = None

            if src_info["type"] == "github":
                latest_v = get_latest_github_version(src_info["repo"], src_info.get("tag_filter"))
            elif src_info["type"] == "debian":
                latest_v, custom_url = get_latest_debian_package(src_info["pkg"], src_info["url_template"])
            elif src_info["type"] == "libretro":
                latest_v = get_latest_libretro_version()

            if not latest_v:
                print(f"  [{app}] ❌ Gagal mendapatkan versi upstream.")
                continue

            is_outdated = (curr_v != latest_v)
            status_icon = "🆙 Pembaruan Tersedia" if is_outdated else "✅ Up-to-date"
            print(f"  [{app}] Versi lokal: {curr_v} | Upstream: {latest_v} -> {status_icon}")

            if is_outdated:
                updates.append({
                    "app": app,
                    "current": curr_v,
                    "latest": latest_v,
                    "custom_url": custom_url,
                    "source": src_info
                })

        if check_only:
            print("\nSelesai memeriksa. Mode --check aktif, tidak ada perubahan yang ditulis.")
            return

        if not updates:
            print("\n🎉 Seluruh aplikasi native sudah menggunakan versi terbaru!")
            return

        selected_updates = []
        if len(updates) > 1 and not target_app:
            # Menu interaktif fzf
            fzf_input = "\n".join([f"{u['app']} ({u['current']} -> {u['latest']})" for u in updates])
            fzf_res, code = run_cmd(f"echo '{fzf_input}' | fzf --multi --prompt='Pilih aplikasi yang ingin diperbarui (TAB pilih, ENTER konfirmasi): ' --header='Navigasi: PANAH | Pilih: TAB | Update: ENTER'")
            if code != 0 or not fzf_res:
                print("Pembaruan dibatalkan.")
                return
            selected_names = [line.split()[0] for line in fzf_res.splitlines()]
            selected_updates = [u for u in updates if u['app'] in selected_names]
        else:
            selected_updates = updates

        print("\n🚀 Memproses pembaruan...")
        for u in selected_updates:
            app = u["app"]
            latest_v = u["latest"]
            print(f"\n📦 Mengupdate {app} ke versi {latest_v}...")

            url = None
            if u["custom_url"]:
                url = u["custom_url"]
            elif "url_pattern" in u["source"]:
                url = u["source"]["url_pattern"].format(version=latest_v)

            if not url:
                print(f"❌ URL untuk {app} tidak dapat dikonstruksi.")
                continue

            new_hash = compute_sri_hash(url)
            if not new_hash:
                print(f"❌ Gagal menghitung hash untuk {app}.")
                continue

            if update_app_in_file(app, latest_v, new_hash, u["custom_url"]):
                print(f"✅ {app} berhasil diperbarui ke {latest_v} (Hash: {new_hash})")
            else:
                print(f"❌ Gagal memperbarui file konfigurasi untuk {app}.")

        print("\n✨ Seluruh proses pembaruan selesai. Jalankan 'git diff' untuk melihat perubahan.")

    if __name__ == "__main__":
        main()
  '';
in
selfLib.mkModule {
  name = "apps.dev.nix.apps-updater";
  description = "Automatic and interactive upstream version updater for native apps (update-native-apps / unau)";

  hmConfig = {
    home.packages = [
      updateScript
      (pkgs.writeShellScriptBin "unau" ''
        exec update-native-apps "$@"
      '')
    ];
  };
}
