import sys
from utils import get_config_path, run_cmd
from nix_parser import parse_apps_versions, update_app_in_file
from scrapers import detect_upstream_version
from hasher import compute_sri_hash

def main():
    args = sys.argv[1:]
    config_path = get_config_path()
    apps = parse_apps_versions(config_path)

    check_only = "--check" in args or "-c" in args
    target_apps = [a for a in args if not a.startswith("-")]

    print("🔍 Memeriksa pembaruan upstream untuk aplikasi native...")
    apps_to_check = target_apps if target_apps else list(apps.keys())

    updates = []
    for app in apps_to_check:
        if app not in apps:
            print(f"⚠️  Aplikasi '{app}' tidak terdaftar di {config_path.name}.")
            continue

        app_info = apps[app]
        curr_v = app_info["version"]
        latest_v, custom_url = detect_upstream_version(app_info)

        if not latest_v:
            print(f"  [{app}] ❌ Gagal mendapatkan versi upstream.")
            continue

        is_outdated = (curr_v != latest_v)
        status_icon = "🆙 Pembaruan Tersedia" if is_outdated else "✅ Up-to-date"
        print(f"  [{app}] Versi lokal: {curr_v} | Upstream: {latest_v} -> {status_icon}")

        if is_outdated:
            updates.append({
                "app": app,
                "info": app_info,
                "current": curr_v,
                "latest": latest_v,
                "custom_url": custom_url
            })

    if check_only:
        print(f"\nSelesai memeriksa {len(apps_to_check)} aplikasi. Mode --check aktif, tidak ada perubahan yang ditulis.")
        return

    if not updates:
        print("\n🎉 Seluruh aplikasi native sudah menggunakan versi terbaru!")
        return

    selected_updates = []
    if len(updates) > 1 and not target_apps:
        # Menu interaktif fzf
        fzf_input = "\n".join([f"{u['app']} ({u['current']} -> {u['latest']})" for u in updates])
        fzf_res, code = run_cmd(
            f"echo '{fzf_input}' | fzf --multi --prompt='Pilih aplikasi yang ingin diperbarui (TAB pilih, ENTER konfirmasi): ' "
            "--header='Navigasi: PANAH | Pilih: TAB | Update: ENTER'"
        )
        if code != 0 or not fzf_res:
            print("Pembaruan dibatalkan.")
            return
        selected_names = [line.split()[0] for line in fzf_res.splitlines()]
        selected_updates = [u for u in updates if u["app"] in selected_names]
    else:
        selected_updates = updates

    if not selected_updates:
        print("Tidak ada aplikasi yang dipilih.")
        return

    print("\n🚀 Memproses pembaruan...")
    for u in selected_updates:
        app = u["app"]
        latest_v = u["latest"]
        app_info = u["info"]
        print(f"\n📦 Mengupdate {app} ke versi {latest_v}...")

        if u["custom_url"]:
            url = u["custom_url"]
        else:
            url = app_info["url_template"].replace("${version}", latest_v)

        if not url:
            print(f"❌ URL untuk {app} tidak dapat dikonstruksi.")
            continue

        new_hash = compute_sri_hash(url)
        if not new_hash:
            print(f"❌ Gagal menghitung hash untuk {app}.")
            continue

        if update_app_in_file(config_path, app, latest_v, new_hash, u["custom_url"]):
            print(f"✅ {app} berhasil diperbarui ke {latest_v} (Hash: {new_hash})")
        else:
            print(f"❌ Gagal memperbarui file konfigurasi untuk {app}.")

    print("\n✨ Seluruh proses pembaruan selesai. Jalankan 'git diff' untuk melihat perubahan.")

if __name__ == "__main__":
    main()
