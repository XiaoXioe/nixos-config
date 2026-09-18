# Single Source of Truth for Native Apps Version Pinning
# Di sini seluruh metadata rilis resmi upstream (versi, URL unduhan, hash sha256) dipusatkan.
# Menggunakan recursive attribute set (`rec { ... }`) agar string versi tidak perlu diulang.
# Untuk memperbarui versi aplikasi apa pun, Anda HANYA perlu mengedit file ini.
{

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
    version = "153.2.0esr-bb8-latest-build5";
    url = "https://www.betterbird.eu/downloads/LinuxArchive/betterbird-${version}.en-US.linux-x86_64.tar.xz";
    hash = "sha256-JZHnAPun5zOaR/jeSRVrin29r35w4oSEAhaayQpLbS0=";
  };

  tradingview = rec {
    version = "2.14.0";
    url = "https://api.snapcraft.io/api/v1/snaps/download/nJdITJ6ZJxdvfu8Ch7n5kH5P99ClzBYV_68.snap";
    hash = "sha256-o/2s1taKfXkp2OzFugXILBGcgCCnPZKcsMJ0X/whjhU=";
  };

  wine = rec {
    version = "11.15";
    url = "https://github.com/kron4ek/Wine-Builds/releases/download/${version}/wine-${version}-staging-amd64-wow64.tar.xz";
    hash = "sha256-vx2fOG/IT0wiJN0XxFv/7PC9zriKArX1/L90ATQQFhM=";
  };
}
