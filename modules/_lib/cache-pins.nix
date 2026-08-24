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
#   storePath   : string — Path di Hydra, e.g. "/nix/store/<hash>-<name>"
#   version     : string — Versi paket (untuk dokumentasi & tracking)
#   channel     : string — Channel Nixpkgs asal pin (e.g. "unstable", "26.05", "25.11")
#   mainProgram : string — (opsional) Nama file biner executable utama
#   system      : string — Target platform (default: "x86_64-linux")
#   fromStore   : string — (opsional) Override binary cache URL
#
# Properti jaminan (3 aturan):
#   - Tidak bergantung pada nixpkgs closure: storePath adalah literal string
#   - Zero Re-Download: Nix cek keberadaan lokal sebelum network call
#   - Zero Re-Unpack: store paths immutable di /nix/store selamanya
#
# Cara update:
#   qcp --update-all        (Dry-run preview)
#   qcp --update-all -w     (Terapkan perubahan ke file ini)
#   qcp --update <pkg> -w   (Update paket spesifik)
{
  # ── CLI & Services ────────────────────────────────────────────────────────

  # Generated: 2026-08-24 | Source: github:NixOS/nixpkgs/nixos-unstable
  # Download Kotor (Full): 25.99 MiB | Download Bersih: 1.89 MiB
  # Library Lokal: 20/23 (87.0%) | Missing: 3 paket (1.89 MiB)
  aria2 = {
    storePath = "/nix/store/b4f4g1hjj1picpgbp1jnzqnabrdhrmp7-aria2-1.37.0-bin";
    version = "1.37.0";
    mainProgram = "aria2c";
    channel = "nixpkgs";
    system = "x86_64-linux";
  };

  # Generated: 2026-08-24 | Source: github:NixOS/nixpkgs/nixos-unstable
  # Download Kotor (Full): 65.23 MiB | Download Bersih: 6.84 MiB
  # Library Lokal: 2/36 (5.6%) | Missing: 34 paket (6.51 MiB)
  kaggle = {
    storePath = "/nix/store/7408zrjw6gxnnwdsk4blbwbhsfhqll2d-python3.14-kaggle-2.2.4";
    version = "2.2.4";
    mainProgram = "kaggle";
    channel = "unstable";
    system = "x86_64-linux";
  };

  # Generated: 2026-08-24 | Source: github:NixOS/nixpkgs/nixos-unstable
  # Download Kotor (Full): 73.29 MiB | Download Bersih: 56.81 MiB
  # Library Lokal: 8/9 (88.9%) | Missing: 1 paket (56.81 MiB)
  opencode = {
    storePath = "/nix/store/897y0qxdg55xaa985v7sw6wqql7frnxh-opencode-1.18.21";
    version = "1.18.21";
    mainProgram = "opencode";
    channel = "unstable";
    system = "x86_64-linux";
  };

  # Generated: 2026-08-24 | Source: github:NixOS/nixpkgs/nixos-unstable
  # Download Kotor (Full): 87.57 MiB | Download Bersih: 0 B
  # Library Lokal: 53/53 (100.0%) | Missing: 0 paket (0 B)
  mcp_proxy = {
    storePath = "/nix/store/2bbvyl341ss0gqlxgw0rdwkzfxd03k7r-mcp-proxy-0.10.0";
    version = "0.10.0";
    mainProgram = "mcp-proxy";
    channel = "nixpkgs";
    system = "x86_64-linux";
  };

  # Generated: 2026-08-24 | Source: github:NixOS/nixpkgs/nixos-unstable
  # Download Kotor (Full): 224.83 MiB | Download Bersih: 6.94 MiB
  # Library Lokal: 147/149 (98.7%) | Missing: 2 paket (6.94 MiB)
  yt_dlp = {
    storePath = "/nix/store/1wn474dn3iizab3nd4v0nwxpdpnqg8ys-yt-dlp-2026.08.19";
    version = "2026.08.19";
    mainProgram = "yt-dlp";
    channel = "unstable";
    system = "x86_64-linux";
  };

  # Generated: 2026-08-24 | Source: github:NixOS/nixpkgs/nixos-unstable
  # Download Kotor (Full): 226.86 MiB | Download Bersih: 8.93 MiB
  # Library Lokal: 148/151 (98.0%) | Missing: 3 paket (8.93 MiB)
  gallery_dl = {
    storePath = "/nix/store/g1wiixhshimzdqlgnfhlyyfcsxwjlyry-gallery-dl-1.32.9";
    version = "1.32.9";
    mainProgram = "gallery-dl";
    channel = "unstable";
    system = "x86_64-linux";
  };

  # Generated: 2026-08-24 | Source: github:NixOS/nixpkgs/nixos-unstable
  # Download Kotor (Full): 40.92 MiB | Download Bersih: 37.77 MiB
  # Library Lokal: 3/14 (21.4%) | Missing: 11 paket (37.77 MiB)
  yazi = {
    storePath = "/nix/store/w2ygw94b3qimz50pcmalqk5fw3sq80ls-yazi-26.8.15";
    version = "26.8.15";
    mainProgram = "yazi";
    channel = "nixpkgs";
    system = "x86_64-linux";
  };

  # Generated: 2026-08-24 | Source: github:NixOS/nixpkgs/nixos-unstable
  # Download Kotor (Full): 23.92 MiB | Download Bersih: 11.19 MiB
  # Library Lokal: 2/3 (66.7%) | Missing: 1 paket (420.78 KiB)
  ruff = {
    storePath = "/nix/store/sddv779f9zwcm72i0nsa8sgy1zjcl2n4-ruff-0.16.3";
    version = "0.16.3";
    mainProgram = "ruff";
    channel = "unstable";
    system = "x86_64-linux";
  };

  # Generated: 2026-08-24 | Source: github:NixOS/nixpkgs/nixos-unstable
  # Download Kotor (Full): 889.77 MiB | Download Bersih: 0 B
  # Library Lokal: 107/107 (100.0%) | Missing: 0 paket (0 B)
  stirling_pdf = {
    storePath = "/nix/store/nrxbzcv28zwb5xsg8ci852662rdwp7as-stirling-pdf-2.14.3";
    version = "2.14.3";
    mainProgram = "Stirling-PDF";
    channel = "unstable";
    system = "x86_64-linux";
  };

  # Generated: 2026-08-24 | Source: github:NixOS/nixpkgs/nixos-unstable
  # Download Kotor (Full): 585.46 MiB | Download Bersih: 0 B
  # Library Lokal: 186/186 (100.0%) | Missing: 0 paket (0 B)
  stirling_pdf_desktop = {
    storePath = "/nix/store/k802w6y92gzddwb0mv0661x40rfxlnxx-stirling-pdf-desktop-2.14.3";
    version = "2.14.3";
    mainProgram = "stirling-pdf";
    channel = "unstable";
    system = "x86_64-linux";
  };

  # ── Emulators ─────────────────────────────────────────────────────────────

  # Generated: 2026-08-24 | Source: github:NixOS/nixpkgs/nixos-unstable
  # Download Kotor (Full): 509.80 MiB | Download Bersih: 208.51 MiB
  # Library Lokal: 270/485 (55.7%) | Missing: 215 paket (208.51 MiB)
  pcsx2 = {
    storePath = "/nix/store/4wzhb6ilrwcpq4a7rbz09fqb98dz3xim-pcsx2-2.6.3";
    version = "2.6.3";
    mainProgram = "pcsx2-qt";
    channel = "nixpkgs";
    system = "x86_64-linux";
  };

  # Generated: 2026-08-24 | Source: github:NixOS/nixpkgs/nixos-unstable
  # Download Kotor (Full): 396.90 MiB | Download Bersih: 101.30 MiB
  # Library Lokal: 259/312 (83.0%) | Missing: 53 paket (101.30 MiB)
  ppsspp = {
    storePath = "/nix/store/9mj5n06c0fbslnk5r8dfn2z8fww3abjx-ppsspp-sdl-1.20.4";
    version = "1.20.4";
    mainProgram = "ppsspp";
    channel = "nixpkgs";
    system = "x86_64-linux";
  };

  # Generated: 2026-08-24 | Source: github:NixOS/nixpkgs/nixos-unstable
  # Download Kotor (Full): 435.19 MiB | Download Bersih: 139.02 MiB
  # Library Lokal: 265/352 (75.3%) | Missing: 87 paket (139.02 MiB)
  dolphin_emu = {
    storePath = "/nix/store/598854dk4lfhl26xpz74x2qql0688hjp-dolphin-emu-2606";
    version = "2606";
    mainProgram = "dolphin-emu";
    channel = "nixpkgs";
    system = "x86_64-linux";
  };

  # ── Desktop Apps ──────────────────────────────────────────────────────────

  # Generated: 2026-08-24 | Source: github:NixOS/nixpkgs/nixos-unstable
  # Download Kotor (Full): 402.18 MiB | Download Bersih: 95.61 MiB
  # Library Lokal: 275/357 (77.0%) | Missing: 82 paket (95.61 MiB)
  gthumb = {
    storePath = "/nix/store/9vidvsna1r9r5v8005is72qs2ddplkjv-gthumb-3.12.10";
    version = "3.12.10";
    mainProgram = "gthumb";
    channel = "nixpkgs";
    system = "x86_64-linux";
  };

  # Generated: 2026-08-24 | Source: github:NixOS/nixpkgs/nixos-unstable
  # Download Kotor (Full): 180.04 MiB | Download Bersih: 64.80 MiB
  # Library Lokal: 127/149 (85.2%) | Missing: 22 paket (64.80 MiB)
  zathura = {
    storePath = "/nix/store/dsnj9rvw0i0ch3lm8gs27rkcd56y3yjk-zathura-with-plugins-2026.05.20";
    version = "2026.05.20";
    mainProgram = "zathura";
    channel = "nixpkgs";
    system = "x86_64-linux";
  };

  # Generated: 2026-08-24 | Source: github:NixOS/nixpkgs/nixos-unstable
  # Download Kotor (Full): 343.57 MiB | Download Bersih: 59.98 MiB
  # Library Lokal: 251/299 (83.9%) | Missing: 48 paket (59.98 MiB)
  gnome_calculator = {
    storePath = "/nix/store/4l9zjvkr9fqyik2v19nq1k1s4ds53jxx-gnome-calculator-50.0";
    version = "50.0";
    mainProgram = "gnome-calculator";
    channel = "nixpkgs";
    system = "x86_64-linux";
  };

  # ── Browsers ──────────────────────────────────────────────────────────────

  # Generated: 2026-08-24 | Source: github:NixOS/nixpkgs/nixos-unstable
  # Download Kotor (Full): 590.16 MiB | Download Bersih: 277.79 MiB
  # Library Lokal: 297/382 (77.7%) | Missing: 85 paket (277.79 MiB)
  brave = {
    storePath = "/nix/store/v77xz9fj5467ylrqpmc0nbhm44sny1mv-brave-1.93.138";
    version = "1.93.138";
    mainProgram = "brave";
    channel = "nixpkgs";
    system = "x86_64-linux";
  };

  # Generated: 2026-08-24 | Source: github:NixOS/nixpkgs/nixos-unstable
  # Download Kotor (Full): 577.67 MiB | Download Bersih: 265.86 MiB
  # Library Lokal: 290/356 (81.5%) | Missing: 66 paket (265.86 MiB)
  chromium = {
    storePath = "/nix/store/rxf83sv2x0ja1hi6vdli6ijll5v15x9j-chromium-151.0.7922.173";
    version = "151.0.7922.173";
    mainProgram = "chromium";
    channel = "nixpkgs";
    system = "x86_64-linux";
  };

  # ── Desktop Shells ────────────────────────────────────────────────────────

  # Generated: 2026-08-24 | Source: github:NixOS/nixpkgs/nixos-unstable
  # Download Kotor (Full): 305.98 MiB | Download Bersih: 39.94 MiB
  # Library Lokal: 259/260 (99.6%) | Missing: 1 paket (21.90 MiB)
  noctalia = {
    storePath = "/nix/store/j59q1n988kakwf32lsrim2dp40625d8b-noctalia-5.0.0-beta.9";
    version = "5.0.0-beta.9";
    channel = "unstable";
    system = "x86_64-linux";
  };
}
