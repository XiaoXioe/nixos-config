# Single Source of Truth for Native Apps Version Pinning
# Di sini seluruh metadata rilis resmi upstream (versi, URL unduhan, hash sha256) dipusatkan.
# Menggunakan recursive attribute set (`rec { ... }`) agar string versi tidak perlu diulang.
# Untuk memperbarui versi aplikasi apa pun, Anda HANYA perlu mengedit file ini.
{
  brave = rec {
    version = "1.93.138";
    url = "https://github.com/brave/brave-browser/releases/download/v${version}/brave-browser_${version}_amd64.deb";
    hash = "sha256-zxiy1EPwZyQeE2YkhMS5Uj8T/wibofwnyI9nkRWGrJ8=";
  };

  chromium = rec {
    version = "151.0.7922.169";
    url = "http://ftp.debian.org/debian/pool/main/c/chromium/chromium_${version}-1_amd64.deb";
    hash = "sha256-ObG142gF6ghGOqLwO1Tpb7d536tqwtGSDLCBIAMuHUw=";
  };

  firefox = rec {
    version = "154.0";
    url = "https://download-installer.cdn.mozilla.net/pub/firefox/releases/${version}/linux-x86_64/en-US/firefox-${version}.tar.xz";
    hash = "sha256-dmXNSasTQXJwdIMlg45WUTatvHbUG712+yTRWgzHeSs=";
  };

  librewolf = rec {
    version = "134.0-1";
    url = "https://gitlab.com/api/v4/projects/24386000/packages/generic/librewolf/${version}/LibreWolf.x86_64.AppImage";
    hash = "sha256-lDMbzbX6gLjiigSsQp6DVlJNqK8SDVK8BNA55Yk3/Q4=";
  };

  tor-browser = rec {
    version = "15.0.20";
    url = "https://dist.torproject.org/torbrowser/${version}/tor-browser-linux-x86_64-${version}.tar.xz";
    hash = "sha256-1DAmM9YFnS2tlOLIg7MRQdx7Paor+lqrsP0p3aGNIuk=";
  };

  discord = rec {
    version = "1.0.154";
    url = "https://stable.dl2.discordapp.net/apps/linux/${version}/discord-${version}.deb";
    hash = "sha256-uhrvP9z+nxAmhe7e/31+NXoebu/S7Vvc53zb2jGBBCg=";
  };

  signal = rec {
    version = "7.36.0";
    url = "https://updates.signal.org/desktop/apt/pool/s/signal-desktop/signal-desktop_${version}_amd64.deb";
    hash = "sha256-exTRx9R+m+qSpcw9U20auAXLTSLirPaJa1rovoSwQEc=";
  };

  materialgram = rec {
    version = "7.0.5.1";
    url = "https://github.com/kukuruzka165/materialgram/releases/download/v${version}/materialgram-v${version}.tar.zst";
    hash = "sha256-s0N/dr+VUp45+epbB3+IKOZunCGwv2b5p7OGDmNrbyQ=";
  };

  obsidian = rec {
    version = "1.13.7";
    url = "https://github.com/obsidianmd/obsidian-releases/releases/download/v${version}/obsidian_${version}_amd64.deb";
    hash = "sha256-F9wztJyz54Xswn7dLqDHnkAgd5i1VP0ohuNuvuevmuA=";
  };

  onlyoffice = rec {
    version = "9.4.0";
    url = "https://github.com/ONLYOFFICE/DesktopEditors/releases/download/v${version}/onlyoffice-desktopeditors_amd64.deb";
    hash = "sha256-QnFDToG+QrFVn9mJ0kv21BNILyeNxqXjKCAqT8Ghhkk=";
  };

  betterbird = rec {
    version = "153.1.0esr-bb7-build2";
    url = "https://www.betterbird.eu/downloads/LinuxArchive/betterbird-${version}.en-US.linux-x86_64.tar.xz";
    hash = "sha256-40E+PcVxRTFJwLdvaG9+rdL2fIJOO/bEiXuqG3+uy2s=";
  };

  tradingview = rec {
    version = "2.14.0";
    url = "https://api.snapcraft.io/api/v1/snaps/download/nJdITJ6ZJxdvfu8Ch7n5kH5P99ClzBYV_68.snap";
    hash = "sha256-o/2s1taKfXkp2OzFugXILBGcgCCnPZKcsMJ0X/whjhU=";
  };

  vscodium = rec {
    version = "1.126.04524";
    url = "https://github.com/VSCodium/vscodium/releases/download/${version}/codium_${version}_amd64.deb";
    hash = "sha256-tO313XhYJvuVOZGOcVZxWAOVRB7hXwkEE/1vieHGF8c=";
  };

  zed = rec {
    version = "1.16.1";
    url = "https://github.com/zed-industries/zed/releases/download/v${version}/zed-linux-x86_64.tar.gz";
    hash = "sha256-nmEa3QxA6GsVA3JFii17eNEBxUkk3HvKjbJ84g2XxmE=";
  };

  bitwarden = rec {
    version = "2026.8.0";
    url = "https://github.com/bitwarden/clients/releases/download/desktop-v${version}/Bitwarden-${version}-amd64.deb";
    hash = "sha256-cg7MOS7vGZJ4CvKqq9RzORaAcVXI7iF+1n8/kyh7tBU=";
  };

  proton-pass = rec {
    version = "1.39.1";
    url = "https://proton.me/download/pass/linux/proton-pass_${version}_amd64.deb";
    hash = "sha256-3Dtt6MG8kN7q7dqr4of/RoIf0fbl9hFFE1XHadpsW+A=";
  };

  ente-auth = rec {
    version = "4.4.25";
    url = "https://github.com/ente-io/ente/releases/download/auth-v${version}/ente-auth-v${version}-x86_64.deb";
    hash = "sha256-AP8xXwQO5p3REA107PTd8Pq9JGx5bRfGFw3IQXLKOK8=";
  };

  dolphin-emu = rec {
    version = "2606.a+dfsg";
    url = "http://ftp.debian.org/debian/pool/main/d/dolphin-emu/dolphin-emu_${version}-1_amd64.deb";
    hash = "sha256-u4xGFX7RgWmRPeVVn7V5ZiXPfAO0fAelU7/riRFv9n8=";
  };

  ppsspp = rec {
    version = "1.20.4";
    url = "https://github.com/hrydgard/ppsspp/releases/download/v${version}/PPSSPP-v${version}-anylinux-x86_64.AppImage";
    hash = "sha256-ZhwJjmt/dhAXGle3xTPOi7pvIxK3HnbWHoUEYZc+uiE=";
  };

  pcsx2 = rec {
    version = "2.6.3";
    url = "https://github.com/PCSX2/pcsx2/releases/download/v${version}/pcsx2-v${version}-linux-appimage-x64-Qt.AppImage";
    hash = "sha256-jOfehhPBewCwECilEt0bgZmLZibrvpOgZ+DrIK7t1b8=";
  };

  retroarch = rec {
    version = "1.22.2";
    url = "https://buildbot.libretro.com/stable/${version}/linux/x86_64/RetroArch.7z";
    hash = "sha256-fWLamiE5fW4blJB4XO2+r9JieBtQEVB2c2++infvMOk=";
  };

  retroarch-cores = rec {
    version = "1.22.2";
    url = "https://buildbot.libretro.com/stable/${version}/linux/x86_64/RetroArch_cores.7z";
    hash = "sha256-S37Y3JfUvwNfzhgsZLVljHZi4unl1CEpU4r71LYJYwc=";
  };

  wine = rec {
    version = "11.15";
    url = "https://github.com/kron4ek/Wine-Builds/releases/download/${version}/wine-${version}-staging-amd64-wow64.tar.xz";
    hash = "sha256-vx2fOG/IT0wiJN0XxFv/7PC9zriKArX1/L90ATQQFhM=";
  };

  gthumb = rec {
    version = "3.12.10";
    url = "http://ftp.debian.org/debian/pool/main/g/gthumb/gthumb_${version}-1+b1_amd64.deb";
    hash = "sha256-bVDTRiJrg5yeeOEvRsUbdx6qKzPgHeQUWUKV95xRk/8=";
  };

  zathura = rec {
    version = "2026.07.18";
    url = "http://ftp.debian.org/debian/pool/main/z/zathura/zathura_${version}-1_amd64.deb";
    hash = "sha256-WMeKyS6/WvUKpOdvjvM6dI+11EgOqvytNvc6+8Ekt8Y=";
  };

  yt-dlp = rec {
    version = "2026.08.19";
    url = "https://github.com/yt-dlp/yt-dlp/releases/download/${version}/yt-dlp_linux";
    hash = "sha256-WBYvm/3CdFjqR7/LMRz0cCjxfYFUqL99aJhh1GOZIwo=";
  };

  gallery-dl = rec {
    version = "1.31.10";
    url = "https://github.com/mikf/gallery-dl/releases/download/v${version}/gallery-dl.bin";
    hash = "sha256-Kj3gbU+SZBcyOE9j7OcT4fCnqggsHAgMDGuQze1E0s8=";
  };

  aria2 = rec {
    version = "1.37.0";
    url = "http://ftp.debian.org/debian/pool/main/a/aria2/aria2_${version}+debian-4+b1_amd64.deb";
    hash = "sha256-/bae6pxbcmfgeUGazmDdGyxmE2JT8nnX4Yus625iav0=";
  };

  tdl = rec {
    version = "0.20.3";
    url = "https://github.com/iyear/tdl/releases/download/v${version}/tdl_Linux_64bit.tar.gz";
    hash = "sha256-9p/gbBf3TDCjuJS1vgXFehsIL1azRsmUAlojAbJppxg=";
  };
}
