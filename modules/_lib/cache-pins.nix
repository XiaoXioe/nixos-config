# modules/_lib/cache-pins.nix
#
# Single Source of Truth untuk Nix Binary Cache Store Path Pins.
# Analogous dengan apps-versions.nix — tapi untuk Hydra/cache.nixos.org artifacts.
#
# Cara kerja:
#   Setiap storePath adalah path asli yang dibangun oleh Hydra dan tersedia di
#   cache.nixos.org. builtins.fetchClosure mengambil path beserta seluruh
#   closure-nya (semua dependencies) langsung dari binary cache.
#
# Format entri:
#   storePath : string — Path di Hydra, e.g. "/nix/store/<hash>-<name>"
#   version   : string — Versi paket (untuk dokumentasi & tracking)
#   system    : string — Target platform
#   fromStore : string — (opsional) Override binary cache URL
#
# Properti jaminan (3 aturan):
#   - Tidak bergantung pada nixpkgs closure: storePath adalah literal string
#   - Zero Re-Download: Nix cek keberadaan lokal sebelum network call
#   - Zero Re-Unpack: store paths immutable di /nix/store selamanya
#
# Cara menambah entri baru:
#   query-cache-pin pkgs.rclone   (atau: qcp pkgs.rclone)
#   query-cache-pin pkgs.mpv
#   query-cache-pin pkgs.syncthing
#   → copy output ke file ini
#
# Cara update versi (misal rclone naik versi):
#   query-cache-pin pkgs.rclone
#   → ganti storePath lama dengan output baru
#   (path lama tetap di /nix/store sampai nix-collect-garbage)
{
  # ── CLI Tools ─────────────────────────────────────────────────────────────

  # Generated: 2026-08-24 | Source: nixpkgs
  # Download Kotor (Full): 50.91 MiB | Download Bersih: 36.19 MiB
  # Library Lokal: 19/19 (100.0%) | Missing: 0 paket (0 B)
  rclone = {
    storePath = "/nix/store/86nhn0hbzqww5s85573nyfw5ci1xc882-rclone-1.75.0";
    version = "1.75.0";
    system = "x86_64-linux";
  };

  # Generated: 2026-08-23 | Source: nixpkgs (nixos-26.05)
  # Download Bersih: 7.19 KiB | Total Disk: 29.98 KiB
  aria2 = {
    storePath = "/nix/store/26xrcn9vw8mgajmsaj91sczmgvwkgkkv-aria2-1.37.0-bin";
    version = "1.37.0";
    system = "x86_64-linux";
  };

  # Generated: 2026-08-24 | Source: github:NixOS/nixpkgs/nixos-unstable
  # Download Kotor (Full): 65.23 MiB | Download Bersih: 6.84 MiB
  # Library Lokal: 2/36 (5.6%) | Missing: 34 paket (6.51 MiB)
  kaggle = {
    storePath = "/nix/store/7408zrjw6gxnnwdsk4blbwbhsfhqll2d-python3.14-kaggle-2.2.4";
    version = "2.2.4";
    system = "x86_64-linux";
  };

  # Generated: 2026-08-24 | Source: github:NixOS/nixpkgs/nixos-unstable
  # Download Kotor (Full): 68.57 MiB | Download Bersih: 58.80 MiB
  # Library Lokal: 1/2 (50.0%) | Missing: 1 paket (2.03 MiB)
  opencode = {
    storePath = "/nix/store/3y4zcklfn3hfk9gn08csfzd3vwfjhkl0-opencode-1.18.18";
    version = "1.18.18";
    system = "x86_64-linux";
  };

  # Generated: 2026-08-24 | Source: github:NixOS/nixpkgs/nixos-unstable
  # Download Kotor (Full): 65.28 MiB | Download Bersih: 5.46 MiB
  # Library Lokal: 13/30 (43.3%) | Missing: 17 paket (5.42 MiB)
  mcp_proxy = {
    storePath = "/nix/store/2bbvyl341ss0gqlxgw0rdwkzfxd03k7r-mcp-proxy-0.10.0";
    version = "0.10.0";
    system = "x86_64-linux";
  };

  # Generated: 2026-08-24 | Source: github:NixOS/nixpkgs/nixos-unstable
  # Download Kotor (Full): 121.11 MiB | Download Bersih: 61.52 MiB
  # Library Lokal: 9/26 (34.6%) | Missing: 17 paket (54.64 MiB)
  yt_dlp = {
    storePath = "/nix/store/hlqrdzxlrpwb2565im6m6r9ivnyyg50l-yt-dlp-2026.08.19";
    version = "2026.08.19";
    system = "x86_64-linux";
  };

  # Generated: 2026-08-24 | Source: github:NixOS/nixpkgs/nixos-unstable
  # Download Kotor (Full): 77.34 MiB | Download Bersih: 17.76 MiB
  # Library Lokal: 9/24 (37.5%) | Missing: 15 paket (15.77 MiB)
  gallery_dl = {
    storePath = "/nix/store/69py2wqk7sd5lsk6l8n03b6vdk8q2jkk-gallery-dl-1.32.9";
    version = "1.32.9";
    system = "x86_64-linux";
  };

  # Generated: 2026-08-24 | Source: github:NixOS/nixpkgs/nixos-unstable
  # Download Kotor (Full): 40.92 MiB | Download Bersih: 37.77 MiB
  # Library Lokal: 3/14 (21.4%) | Missing: 11 paket (37.77 MiB)
  yazi = {
    storePath = "/nix/store/w2ygw94b3qimz50pcmalqk5fw3sq80ls-yazi-26.8.15";
    version = "26.8.15";
    system = "x86_64-linux";
  };

  # Generated: 2026-08-24 | Source: github:NixOS/nixpkgs/nixos-unstable
  # Download Kotor (Full): 34.28 MiB | Download Bersih: 21.56 MiB
  # Library Lokal: 2/3 (66.7%) | Missing: 1 paket (420.78 KiB)
  uv = {
    storePath = "/nix/store/q48w4bd5w98g692nwf8acdngviqzaz9n-uv-0.12.5";
    version = "0.12.5";
    system = "x86_64-linux";
  };

  # Generated: 2026-08-24 | Source: github:NixOS/nixpkgs/nixos-unstable
  # Download Kotor (Full): 23.92 MiB | Download Bersih: 11.19 MiB
  # Library Lokal: 2/3 (66.7%) | Missing: 1 paket (420.78 KiB)
  ruff = {
    storePath = "/nix/store/sddv779f9zwcm72i0nsa8sgy1zjcl2n4-ruff-0.16.3";
    version = "0.16.3";
    system = "x86_64-linux";
  };

  # Generated: 2026-08-24 | Source: github:NixOS/nixpkgs/nixos-unstable
  # Download Kotor (Full): 810.79 MiB | Download Bersih: 801.02 MiB
  # Library Lokal: 1/2 (50.0%) | Missing: 1 paket (474.00 MiB)
  stirling_pdf = {
    storePath = "/nix/store/nrxbzcv28zwb5xsg8ci852662rdwp7as-stirling-pdf-2.14.3";
    version = "2.14.3";
    mainProgram = "Stirling-PDF";
    system = "x86_64-linux";
  };

  # Generated: 2026-08-24 | Source: github:NixOS/nixpkgs/nixos-unstable
  # Download Kotor (Full): 399.42 MiB | Download Bersih: 371.57 MiB
  # Library Lokal: 21/31 (67.7%) | Missing: 10 paket (64.05 MiB)
  stirling_pdf_desktop = {
    storePath = "/nix/store/k802w6y92gzddwb0mv0661x40rfxlnxx-stirling-pdf-desktop-2.14.3";
    version = "2.14.3";
    system = "x86_64-linux";
  };

  # ── Emulators ─────────────────────────────────────────────────────────────────

  # Generated: 2026-08-24 | Source: nixpkgs
  # Download Kotor (Full): 177.25 MiB | Download Bersih: 22.11 MiB
  # Library Lokal: 45/48 (93.8%) | Missing: 3 paket (1.56 MiB)
  pcsx2 = {
    storePath = "/nix/store/2klw35cgdymps4svqwmm1wgxwxkmfnm9-pcsx2-2.6.3";
    version = "2.6.3";
    mainProgram = "pcsx2-qt";
    system = "x86_64-linux";
  };

  # Generated: 2026-08-24 | Source: nixpkgs
  # Menggunakan SDL2 frontend untuk stabilitas penuh tanpa Qt SIGSEGV
  ppsspp = {
    storePath = "/nix/store/ay1i8qc4lg2q4andxz948k4scx9b2mrd-ppsspp-sdl-1.20.4";
    version = "1.20.4";
    mainProgram = "PPSSPPSDL";
    system = "x86_64-linux";
  };

  # Generated: 2026-08-24 | Source: nixpkgs
  # Download Kotor (Full): 113.67 MiB | Download Bersih: 28.22 MiB
  # Library Lokal: 39/39 (100.0%) | Missing: 0 paket (0 B)
  dolphin_emu = {
    storePath = "/nix/store/3hq9jpjxh0rcmc4is4dvy8g2nnl0r6ss-dolphin-emu-2603a";
    version = "2603a";
    mainProgram = "dolphin-emu";
    system = "x86_64-linux";
  };

  # Generated: 2026-08-24 | Source: nixpkgs
  # Download Kotor (Full): 19.89 MiB | Download Bersih: 7.15 MiB
  # Library Lokal: 2/4 (50.0%) | Missing: 2 paket (7.15 MiB)
  retroarch = {
    storePath = "/nix/store/13y35y5lsjginq2h8a69wv6dygrjfav2-retroarch-with-cores-1.22.2";
    version = "1.22.2";
    system = "x86_64-linux";
  };

  # ── Desktop apps ──────────────────────────────────────────────────────────────

  # Generated: 2026-08-23 | Source: nixpkgs
  # Download Bersih: 6.38 MiB | Total Disk: 16.60 MiB
  # Library Lokal: 32/32 (100.0%) | Missing: 0 paket (0 B)
  gthumb = {
    storePath = "/nix/store/dzva0rvdpvaij2df3gm3fi3x3fjz8sw5-gthumb-3.12.10";
    version = "3.12.10";
    system = "x86_64-linux";
  };

  # Generated: 2026-08-23 | Source: nixpkgs
  # Download Bersih: 3.11 KiB | Total Disk: 36.80 KiB
  # Library Lokal: 10/10 (100.0%) | Missing: 0 paket (0 B)
  zathura = {
    storePath = "/nix/store/4xb53xjlryva30ihlvr3445vdva1jqwk-zathura-with-plugins-2026.05.20";
    version = "2026.05.20";
    system = "x86_64-linux";
  };

  # Generated: 2026-08-23 | Source: nixpkgs
  # Download Kotor (Full): 36.99 MiB | Download Bersih: 2.97 MiB
  # Library Lokal: 18/20 (90.0%) | Missing: 2 paket (1.18 MiB)
  gnome_calculator = {
    storePath = "/nix/store/0sfnnqmp859kvcgj5cxym050b33mw1i1-gnome-calculator-50.0";
    version = "50.0";
    system = "x86_64-linux";
  };

  # ── Browsers ──────────────────────────────────────────────────────────────

  # Generated: 2026-08-23 | Source: nixpkgs
  # Download Bersih: 185.75 MiB | Total Disk: 447.91 MiB
  # Library Lokal: 57/57 (100.0%) | Missing: 0 paket (0 B)
  brave = {
    storePath = "/nix/store/f3ynz02x1dq653lwhzjw83lfl47qzyjy-brave-1.93.129";
    version = "1.93.129";
    system = "x86_64-linux";
  };

  # Generated: 2026-08-23 | Source: nixpkgs
  # Download Kotor (Full): 237.93 MiB | Download Bersih: 202.65 MiB
  # Library Lokal: 14/16 (87.5%) | Missing: 2 paket (202.64 MiB)
  chromium = {
    storePath = "/nix/store/j8hc3kdypr2gaa2w3dq0a370lwfzbasf-chromium-151.0.7922.137";
    version = "151.0.7922.137";
    system = "x86_64-linux";
  };

  # Generated: 2026-08-24 | Source: nixpkgs
  # Download Kotor (Full): 28.78 MiB | Download Bersih: 12.47 KiB
  # Library Lokal: 14/14 (100.0%) | Missing: 0 paket (0 B)
  cowsay = {
    storePath = "/nix/store/9xspds4a6qncn5kb8mgp6l2sdd4iplgf-cowsay-3.8.4";
    version = "3.8.4";
    system = "x86_64-linux";
  };

  # Generated: 2026-08-24 | Source: github:NixOS/nixpkgs/nixos-unstable
  # Download Kotor (Full): 305.98 MiB | Download Bersih: 39.94 MiB
  # Library Lokal: 259/260 (99.6%) | Missing: 1 paket (21.90 MiB)
  noctalia = {
    storePath = "/nix/store/j59q1n988kakwf32lsrim2dp40625d8b-noctalia-5.0.0-beta.9";
    version = "5.0.0-beta.9";
    system = "x86_64-linux";
  };

  # ── Tambah entri lain dengan: query-cache-pin pkgs.<name> (atau: qcp pkgs.<name>) ───
  #
  # Contoh paket yang bisa di-pin:
  #
  # Systemd/Services:
  #   syncthing, borgbackup, restic, tailscale, wireguard-tools, ...
  #
  # GUI Apps:
  #   mpv, vlc, gimp, inkscape, libreoffice, evince, eog, ...
  #
  # CLI Tools:
  #   git, curl, wget, ripgrep, fd, bat, eza, fzf, jq, ...
  #
  # Dev Tools:
  #   python3, nodejs, rustup, go, ...
}
