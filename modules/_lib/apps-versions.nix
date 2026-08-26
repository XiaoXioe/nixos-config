# Single Source of Truth for Native Apps Version Pinning
# Di sini seluruh metadata rilis resmi upstream (versi, URL unduhan, hash sha256) dipusatkan.
# Menggunakan recursive attribute set (`rec { ... }`) agar string versi tidak perlu diulang.
# Untuk memperbarui versi aplikasi apa pun, Anda HANYA perlu mengedit file ini.
{
  librewolf = rec {
    version = "134.0-1";
    url = "https://gitlab.com/api/v4/projects/24386000/packages/generic/librewolf/${version}/LibreWolf.x86_64.AppImage";
    hash = "sha256-lDMbzbX6gLjiigSsQp6DVlJNqK8SDVK8BNA55Yk3/Q4=";
  };

  discord = rec {
    version = "1.0.154";
    url = "https://stable.dl2.discordapp.net/apps/linux/${version}/discord-${version}.deb";
    hash = "sha256-uhrvP9z+nxAmhe7e/31+NXoebu/S7Vvc53zb2jGBBCg=";
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

  zed = rec {
    version = "1.16.1";
    url = "https://github.com/zed-industries/zed/releases/download/v${version}/zed-linux-x86_64.tar.gz";
    hash = "sha256-nmEa3QxA6GsVA3JFii17eNEBxUkk3HvKjbJ84g2XxmE=";
  };

  wine = rec {
    version = "11.15";
    url = "https://github.com/kron4ek/Wine-Builds/releases/download/${version}/wine-${version}-staging-amd64-wow64.tar.xz";
    hash = "sha256-vx2fOG/IT0wiJN0XxFv/7PC9zriKArX1/L90ATQQFhM=";
  };

  tdl = rec {
    version = "0.20.3";
    url = "https://github.com/iyear/tdl/releases/download/v${version}/tdl_Linux_64bit.tar.gz";
    hash = "sha256-9p/gbBf3TDCjuJS1vgXFehsIL1azRsmUAlojAbJppxg=";
  };

  zellij = rec {
    version = "0.43.1";
    url = "https://github.com/zellij-org/zellij/releases/download/v${version}/zellij-x86_64-unknown-linux-musl.tar.gz";
    hash = "sha256-VB2Y7+9VWCk++FrZrNKeTZILbogVE7nnclXYIHAg11o=";
  };
}
