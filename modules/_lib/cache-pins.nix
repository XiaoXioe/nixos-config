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
#   ncp update --all        (Dry-run preview)
#   ncp update --all -w     (Terapkan perubahan ke file ini)
#   ncp update <pkg> -w     (Update paket spesifik)
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

  # Generated: 2026-08-26 | Source: nixpkgs
  # Download Kotor (Full): 159.65 MiB | Download Bersih: 12.34 MiB
  # Library Lokal: 178/182 (97.8%) | Missing: 4 paket (12.34 MiB)
  yazi = {
    storePath = "/nix/store/f6xig5fc7n16f0ah6khy483w6ly3r3v9-yazi-26.5.6";
    version = "26.5.6";
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

  # Generated: 2026-08-26 | Source: github:NixOS/nixpkgs/nixos-unstable
  # Download Kotor (Full): 402.18 MiB | Download Bersih: 0 B
  # Library Lokal: 357/357 (100.0%) | Missing: 0 paket (0 B)
  gthumb = {
    storePath = "/nix/store/9vidvsna1r9r5v8005is72qs2ddplkjv-gthumb-3.12.10";
    version = "3.12.10";
    mainProgram = "gthumb";
    channel = "unstable";
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

  # Generated: 2026-08-25 | Source: nixpkgs
  # Download Kotor (Full): 725.28 MiB | Download Bersih: 405.27 MiB
  # Library Lokal: 221/229 (96.5%) | Missing: 8 paket (405.27 MiB)
  onlyoffice = {
    storePath = "/nix/store/q0hfwvlncxak4w4p9xg0kbvb58ybm4x8-onlyoffice-desktopeditors-9.1.0";
    pname = "onlyoffice-desktopeditors";
    version = "9.1.0";
    mainProgram = "onlyoffice-desktopeditors";
    channel = "nixpkgs";
    system = "x86_64-linux";
  };

  # Generated: 2026-08-25 | Source: nixpkgs
  # Download Kotor (Full): 555.19 MiB | Download Bersih: 154.27 MiB
  # Library Lokal: 333/339 (98.2%) | Missing: 6 paket (154.27 MiB)
  signal = {
    storePath = "/nix/store/k215h10vki04jsd808kz76fi4rpmag3r-signal-desktop-8.21.0";
    pname = "signal-desktop";
    version = "8.21.0";
    mainProgram = "signal-desktop";
    channel = "nixpkgs";
    system = "x86_64-linux";
  };

  # Generated: 2026-08-25 | Source: nixpkgs
  # Download Kotor (Full): 433.11 MiB | Download Bersih: 150.24 MiB
  # Library Lokal: 196/198 (99.0%) | Missing: 2 paket (150.24 MiB)
  vscodium = {
    storePath = "/nix/store/g80pwk7r7b25148rxz6wffvj3m8arn6x-vscodium-1.116.02821";
    version = "1.116.02821";
    mainProgram = "codium";
    channel = "nixpkgs";
    system = "x86_64-linux";
  };

  # Generated: 2026-08-26 | Source: nixpkgs
  # Download Kotor (Full): 494.95 MiB | Download Bersih: 0 B
  # Library Lokal: 302/302 (100.0%) | Missing: 0 paket (0 B)
  bitwarden = {
    storePath = "/nix/store/8ybdisnb034z6ksgga0hijg46m02iadv-bitwarden-desktop-2026.7.0";
    version = "2026.7.0";
    mainProgram = "bitwarden";
    channel = "nixpkgs";
    system = "x86_64-linux";
  };

  # Generated: 2026-08-26 | Source: nixpkgs
  # Download Kotor (Full): 486.04 MiB | Download Bersih: 0 B
  # Library Lokal: 302/302 (100.0%) | Missing: 0 paket (0 B)
  proton_pass = {
    storePath = "/nix/store/ns3bf502dgsdnr7mppzp3kjhlyp841gj-proton-pass-1.36.1";
    version = "1.36.1";
    mainProgram = "proton-pass";
    channel = "nixpkgs";
    system = "x86_64-linux";
  };

  # Generated: 2026-08-26 | Source: nixpkgs
  # Download Kotor (Full): 119.15 MiB | Download Bersih: 0 B
  # Library Lokal: 118/118 (100.0%) | Missing: 0 paket (0 B)
  ente_auth = {
    storePath = "/nix/store/zmcpbnmp11n2lzv526ly0ldvkzpzn25g-ente-auth-4.4.17";
    version = "4.4.17";
    mainProgram = "enteauth";
    channel = "nixpkgs";
    system = "x86_64-linux";
  };

  # ── Browsers ──────────────────────────────────────────────────────────────

  # Generated: 2026-08-26 | Source: nixpkgs
  # Download Kotor (Full): 443.47 MiB | Download Bersih: 142.36 MiB
  # Library Lokal: 316/320 (98.8%) | Missing: 4 paket (142.36 MiB)
  firefox = {
    storePath = "/nix/store/q311vc08d8airf0dml2301rwjb48iaiw-firefox-154.0";
    version = "154.0";
    mainProgram = "firefox";
    channel = "nixpkgs";
    system = "x86_64-linux";
  };

  # Generated: 2026-08-26 | Source: nixpkgs
  # Download Kotor (Full): 526.93 MiB | Download Bersih: 163.19 MiB
  # Library Lokal: 312/313 (99.7%) | Missing: 1 paket (163.19 MiB)
  tor_browser = {
    storePath = "/nix/store/wfn8gsjzq1gw0b5ka2fgj03dh8rlhljr-tor-browser-15.0.20";
    version = "15.0.20";
    mainProgram = "tor-browser";
    channel = "nixpkgs";
    system = "x86_64-linux";
  };

  # Generated: 2026-08-26 | Source: nixpkgs
  # Download Kotor (Full): 583.91 MiB | Download Bersih: 186.12 MiB
  # Library Lokal: 377/379 (99.5%) | Missing: 2 paket (186.12 MiB)
  brave = {
    storePath = "/nix/store/g2mvyrw3pzi0dfw7f281rj7g10vhmzcn-brave-1.93.138";
    version = "1.93.138";
    mainProgram = "brave";
    channel = "nixpkgs";
    system = "x86_64-linux";
  };

  # Generated: 2026-08-26 | Source: nixpkgs
  # Download Kotor (Full): 571.40 MiB | Download Bersih: 202.63 MiB
  # Library Lokal: 349/353 (98.9%) | Missing: 4 paket (202.63 MiB)
  chromium = {
    storePath = "/nix/store/53p8msmqxpi829zdrw6qkvaamidxy9cj-chromium-151.0.7922.173";
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
