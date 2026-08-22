import re
from utils import run_cmd

def parse_apps_versions(filepath):
    """Mengurai blok aplikasi dari modules/_lib/apps-versions.nix."""
    content = filepath.read_text(encoding="utf-8")
    pattern = re.compile(r'(?m)^\s*([a-zA-Z0-9_-]+)\s*=\s*rec\s*\{(.*?)\n\s*\};', re.DOTALL)
    apps = {}
    for m in pattern.finditer(content):
        app_name = m.group(1)
        body = m.group(2)
        v = re.search(r'version\s*=\s*"([^"]+)"', body)
        u = re.search(r'url\s*=\s*"([^"]+)"', body)
        h = re.search(r'hash\s*=\s*"([^"]+)"', body)
        if v and u and h:
            apps[app_name] = {
                "name": app_name,
                "version": v.group(1),
                "url_template": u.group(1),
                "hash": h.group(1),
                "raw_body": body
            }
    return apps

def update_app_in_file(filepath, app_name, new_version, new_hash, new_url=None):
    """Memperbarui entri aplikasi pada apps-versions.nix dan memformatnya dengan nixfmt."""
    content = filepath.read_text(encoding="utf-8")

    block_pattern = re.compile(rf'(?m)(^\s*{re.escape(app_name)}\s*=\s*rec\s*\{{)(.*?)(\n\s*\}};)', re.DOTALL)
    match = block_pattern.search(content)
    if not match:
        print(f"Error: Blok untuk {app_name} tidak ditemukan di {filepath}")
        return False

    header, body, footer = match.groups()

    # Ganti version
    body = re.sub(r'version\s*=\s*"[^"]+";', f'version = "{new_version}";', body)
    # Ganti hash
    body = re.sub(r'hash\s*=\s*"[^"]+";', f'hash = "{new_hash}";', body)
    # Ganti url jika nama file berubah (khususnya untuk rilis Debian pool / Snapcraft / Proton Pass)
    if new_url:
        deb_filename = new_url.split('/')[-1]
        deb_formatted = deb_filename.replace(new_version, "${version}")
        base_dir = "/".join(new_url.split('/')[:-1]) + "/"
        formatted_url = base_dir + deb_formatted
        body = re.sub(r'url\s*=\s*"[^"]+";', f'url = "{formatted_url}";', body)

    new_content = content[:match.start()] + header + body + footer + content[match.end():]
    filepath.write_text(new_content, encoding="utf-8")
    run_cmd(f"nixfmt {filepath}")
    return True
