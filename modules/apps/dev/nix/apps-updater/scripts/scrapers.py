import json
import re
import urllib.request
from utils import natural_sort_key, run_cmd, url_exists

def get_github_version(repo, tag_prefix, url_tmpl):
    """Mendeteksi versi terbaru dari GitHub Release yang memiliki aset valid."""
    # Prioritas 1: Ambil official latest release view
    out, code = run_cmd(f"gh release view --repo {repo} --json tagName,isDraft,isPrerelease")
    if code == 0 and out:
        try:
            data = json.loads(out)
            tag = data.get("tagName", "")
            v = None
            if "Wine-Builds" in repo:
                if re.match(r'^[0-9]+(\.[0-9]+)*$', tag):
                    v = tag
            elif tag_prefix:
                if tag.startswith(tag_prefix):
                    v = tag[len(tag_prefix):]
            else:
                clean_tag = tag.lstrip("v")
                if re.match(r'^[0-9]+(\.[0-9]+)*$', clean_tag):
                    v = clean_tag
            if v:
                candidate_url = url_tmpl.replace("${version}", v)
                if url_exists(candidate_url):
                    return v, None
        except Exception:
            pass

    # Prioritas 2: Fallback ke release list (filter out drafts & pre-releases)
    out, code = run_cmd(f"gh release list --repo {repo} --limit 30 --json tagName,isDraft,isPrerelease")
    if code == 0 and out:
        try:
            data = json.loads(out)
            for item in data:
                if item.get("isDraft") or item.get("isPrerelease"):
                    continue
                tag = item.get("tagName", "")
                v = None
                if "Wine-Builds" in repo:
                    if re.match(r'^[0-9]+(\.[0-9]+)*$', tag):
                        v = tag
                elif tag_prefix:
                    if tag.startswith(tag_prefix):
                        v = tag[len(tag_prefix):]
                else:
                    clean_tag = tag.lstrip("v")
                    if re.match(r'^[0-9]+(\.[0-9]+)*$', clean_tag):
                        v = clean_tag
                if v:
                    candidate_url = url_tmpl.replace("${version}", v)
                    if url_exists(candidate_url):
                        return v, None
        except Exception:
            pass
    return None, None

def get_debian_version(url_tmpl):
    """Mendeteksi versi paket terbaru dari Debian pool directory."""
    base_dir = "/".join(url_tmpl.split("/")[:-1]) + "/"
    filename_tmpl = url_tmpl.split("/")[-1]
    pkg_name = filename_tmpl.split("_")[0]
    try:
        req = urllib.request.Request(base_dir, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=10) as response:
            html = response.read().decode('utf-8')
        matches = set(re.findall(rf'{pkg_name}_([0-9][^\"\'\s<>]*_amd64\.deb)', html))
        valid_debs = [m for m in matches if not "~bpo" in m and not "-dbg" in m]
        if not valid_debs:
            valid_debs = list(matches)
        if valid_debs:
            valid_debs.sort(key=natural_sort_key)
            latest_deb = valid_debs[-1]
            full_ver = latest_deb[:-len("_amd64.deb")]
            m = re.match(r'^(.*?)(?:\+debian.*|-[0-9a-zA-Z\.\+~]+)$', full_ver)
            upstream_v = m.group(1) if m else full_ver
            full_url = base_dir + f"{pkg_name}_" + latest_deb
            return upstream_v, full_url
    except Exception:
        pass
    return None, None

def get_libretro_version():
    """Mendeteksi versi rilis stabil Libretro buildbot."""
    try:
        req = urllib.request.Request("https://buildbot.libretro.com/stable/", headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=10) as response:
            html = response.read().decode('utf-8')
        versions = re.findall(r'(?:stable/|\bhref=[\"\'])([0-9]+\.[0-9]+(?:\.[0-9]+)?)/?[\"\']?', html)
        versions = [v for v in versions if re.match(r'^1\.[0-9]+(?:\.[0-9]+)?$', v)]
        if versions:
            sorted_v = sorted(set(versions), key=natural_sort_key)
            return sorted_v[-1], None
    except Exception:
        pass
    return None, None

def get_mozilla_firefox_version():
    """Mendeteksi versi rilis resmi Firefox dari Mozilla Product Details API."""
    try:
        req = urllib.request.Request("https://product-details.mozilla.org/1.0/firefox_versions.json", headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=10) as response:
            data = json.loads(response.read().decode('utf-8'))
        return data.get("LATEST_FIREFOX_VERSION"), None
    except Exception:
        pass
    return None, None

def get_librewolf_version():
    """Mendeteksi rilis terbaru LibreWolf dari GitLab releases API."""
    try:
        req = urllib.request.Request("https://gitlab.com/api/v4/projects/24386000/releases", headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=10) as response:
            data = json.loads(response.read().decode('utf-8'))
        if data:
            tag = data[0]["tag_name"].lstrip("v")
            return tag, None
    except Exception:
        pass
    return None, None

def get_tor_browser_version():
    """Mendeteksi rilis terbaru Tor Browser dari direktori resmi dist.torproject.org."""
    try:
        req = urllib.request.Request("https://dist.torproject.org/torbrowser/", headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=10) as response:
            html = response.read().decode('utf-8')
        v = re.findall(r'href=\"([0-9]+\.[0-9]+(?:\.[0-9]+)?)/?\"', html)
        if v:
            return sorted(set(v), key=natural_sort_key)[-1], None
    except Exception:
        pass
    return None, None

def get_discord_version():
    """Mendeteksi rilis terbaru Discord Linux deb melalui endpoint redirect."""
    try:
        req = urllib.request.Request("https://discord.com/api/download?platform=linux&format=deb", headers={'User-Agent': 'Mozilla/5.0'})
        opener = urllib.request.build_opener(urllib.request.HTTPRedirectHandler)
        res = opener.open(req, timeout=10)
        final_url = res.geturl()
        m = re.search(r'/linux/([0-9\.]+)/', final_url)
        if m:
            return m.group(1), None
    except Exception:
        pass
    return None, None

def get_signal_version():
    """Mendeteksi rilis resmi Signal Desktop dari GitHub."""
    out, code = run_cmd("gh release view --repo signalapp/Signal-Desktop --json tagName --jq .tagName")
    if code == 0 and out:
        return out.lstrip("v"), None
    return None, None

def get_betterbird_version():
    """Mendeteksi rilis terbaru Betterbird Linux dari arsip unduhan resmi."""
    try:
        req = urllib.request.Request("https://www.betterbird.eu/downloads/", headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=10) as response:
            html = response.read().decode('utf-8')
        matches = re.findall(r'href=\"[^\"]*LinuxArchive/betterbird-([0-9a-zA-Z\.\-]+)\.en-US\.linux-x86_64\.tar\.xz\"', html)
        matches = [m for m in matches if not "Previous" in m]
        if matches:
            sorted_bb = sorted(set(matches), key=natural_sort_key)
            v = sorted_bb[-1]
            full_url = f"https://www.betterbird.eu/downloads/LinuxArchive/betterbird-{v}.en-US.linux-x86_64.tar.xz"
            return v, full_url
    except Exception:
        pass
    return None, None

def get_tradingview_version():
    """Mendeteksi rilis terbaru TradingView dari Snapcraft API."""
    try:
        req = urllib.request.Request("https://api.snapcraft.io/v2/snaps/info/tradingview", headers={'User-Agent': 'Mozilla/5.0', 'Snap-Device-Series': '16'})
        with urllib.request.urlopen(req, timeout=10) as response:
            data = json.loads(response.read().decode('utf-8'))
        for ch in data.get("channel-map", []):
            if ch.get("channel", {}).get("name") == "stable":
                v = ch.get("version")
                dl = ch.get("download", {}).get("url")
                return v, dl
    except Exception:
        pass
    return None, None

def get_proton_pass_version():
    """Mendeteksi rilis terbaru Proton Pass dari endpoint rilis resmi."""
    try:
        req = urllib.request.Request("https://proton.me/download/pass/linux/x64/version.json", headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=10) as response:
            data = json.loads(response.read().decode('utf-8'))
        releases = data.get("Releases", [])
        if releases:
            v = releases[0].get("Version")
            files = releases[0].get("File", [])
            dl = files[0].get("Url") if files else None
            return v, dl
    except Exception:
        pass
    return None, None

def detect_upstream_version(app_info):
    """Dispatcher universal pendeteksi versi hulu."""
    url_tmpl = app_info["url_template"]

    # 1. GitHub Releases
    gh_match = re.search(r'https?://github\.com/([^/]+/[^/]+)/releases/download/([^/]+)/', url_tmpl)
    if gh_match:
        repo = gh_match.group(1)
        tag_tmpl = gh_match.group(2)
        tag_prefix = "" if "Wine-Builds" in repo else tag_tmpl.replace("${version}", "")
        return get_github_version(repo, tag_prefix, url_tmpl)

    # 2. Debian Pool
    if "ftp.debian.org/debian/pool/" in url_tmpl:
        return get_debian_version(url_tmpl)

    # 3. Libretro Buildbot
    if "buildbot.libretro.com/stable/" in url_tmpl:
        return get_libretro_version()

    # 4. Mozilla Firefox
    if "download-installer.cdn.mozilla.net/pub/firefox/" in url_tmpl:
        return get_mozilla_firefox_version()

    # 5. LibreWolf
    if "gitlab.com/api/v4/projects/24386000/" in url_tmpl:
        return get_librewolf_version()

    # 6. Tor Browser
    if "dist.torproject.org/torbrowser/" in url_tmpl:
        return get_tor_browser_version()

    # 7. Discord
    if "stable.dl2.discordapp.net" in url_tmpl:
        return get_discord_version()

    # 8. Signal
    if "updates.signal.org/desktop/" in url_tmpl:
        return get_signal_version()

    # 9. Betterbird
    if "betterbird.eu" in url_tmpl:
        return get_betterbird_version()

    # 10. TradingView
    if "api.snapcraft.io" in url_tmpl:
        return get_tradingview_version()

    # 11. Proton Pass
    if "proton.me/download/pass/" in url_tmpl:
        return get_proton_pass_version()

    return None, None
