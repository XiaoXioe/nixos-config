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

  # Generated: 2026-08-31 | Source: git+https://github.com/NixOS/nixpkgs?shallow=1&ref=nixos-unstable
  # Ukuran Closure Disk: 238.59 MiB (Uncompressed) | Download Kotor: 73.30 MiB
  # Download Bersih: 73.30 MiB | Library Lokal: 0/9 (0.0%) | Missing: 9 paket (73.30 MiB)
  opencode = {
    storePath = "/nix/store/89s5dglfs84sk22y6mp8f0paszs25zjy-opencode-1.18.25";
    version = "1.18.25";
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

  # Generated: 2026-08-26 | Source: nixpkgs
  # Ukuran Closure Disk: 1.27 GiB (Uncompressed) | Download Kotor: 888.56 MiB
  # Download Bersih: 801.02 MiB | Library Lokal: 104/107 (97.2%) | Missing: 3 paket (801.02 MiB)
  stirling_pdf = {
    storePath = "/nix/store/azsmf5sci4c118fb5q9lrf7cg7sr5h6x-stirling-pdf-2.14.3";
    version = "2.14.3";
    mainProgram = "Stirling-PDF";
    channel = "nixpkgs";
    system = "x86_64-linux";
  };

  # Generated: 2026-08-26 | Source: nixpkgs
  # Ukuran Closure Disk: 1.19 GiB (Uncompressed) | Download Kotor: 583.88 MiB
  # Download Bersih: 0 B | Library Lokal: 190/190 (100.0%) | Missing: 0 paket (0 B)
  stirling_pdf_desktop = {
    storePath = "/nix/store/hykha9bijag2agvxqshzi83i79qxhhs7-stirling-pdf-desktop-2.14.3";
    version = "2.14.3";
    mainProgram = "stirling-pdf";
    channel = "nixpkgs";
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

  # Generated: 2026-08-26 | Source: nixpkgs
  # Ukuran Closure Disk: 1.22 GiB (Uncompressed) | Download Kotor: 427.72 MiB
  # Download Bersih: 28.42 MiB | Library Lokal: 346/349 (99.1%) | Missing: 3 paket (28.42 MiB)
  dolphin_emu = {
    storePath = "/nix/store/3hq9jpjxh0rcmc4is4dvy8g2nnl0r6ss-dolphin-emu-2603a";
    version = "2603a";
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

  # Generated: 2026-08-27 | Source: nixpkgs
  # Ukuran Closure Disk: 1.44 GiB (Uncompressed) | Download Kotor: 511.09 MiB
  # Download Bersih: 42.04 MiB | Library Lokal: 301/302 (99.7%) | Missing: 1 paket (42.04 MiB)
  bitwarden = {
    storePath = "/nix/store/gz6dcrvvrahmdwa5mw900hjsncrnwqrm-bitwarden-desktop-2026.8.0";
    version = "2026.8.0";
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

  # Generated: 2026-08-26 | Source: nixpkgs
  # Download Kotor (Full): 696.85 MiB | NAR: 2.36 MiB
  nixd = {
    storePath = "/nix/store/z7gvh80g5ni3i3cr2fm613fpz6dcjam3-nixd-2.9.1";
    version = "2.9.1";
    mainProgram = "nixd";
    channel = "nixpkgs";
    system = "x86_64-linux";
  };
  # Generated: 2026-08-26 | Source: nixpkgs
  # Download Kotor (Full): 243.89 MiB | NAR: 11.56 MiB
  sqlfluff = {
    storePath = "/nix/store/7icxzbpc60b4fmb0bm0ag8wk02nx6pl5-sqlfluff-4.2.1";
    version = "4.2.1";
    mainProgram = "sqlfluff";
    channel = "nixpkgs";
    system = "x86_64-linux";
  };
  # Generated: 2026-08-26 | Source: nixpkgs
  # Download Kotor (Full): 205.66 MiB | NAR: 2.01 MiB
  black = {
    storePath = "/nix/store/q2z1k40qjmlqlkjl27mgmyjlmlnxn7ja-python3.13-black-25.1.0";
    version = "25.1.0";
    mainProgram = "black";
    channel = "nixpkgs";
    system = "x86_64-linux";
  };

  # ── Media & Processing (Batch A) ──────────────────────────────────────────
  # Generated: 2026-08-26 | Source: nixpkgs
  # Download Kotor (Full): 1045.10 MiB | NAR: 1.04 MiB
  ffmpeg = {
    storePath = "/nix/store/gqvsn463s7nx9aaxbmp9fjy1n2zx4php-ffmpeg-8.1.2-bin";
    version = "8.1.2";
    mainProgram = "ffmpeg";
    channel = "nixpkgs";
    system = "x86_64-linux";
  };
  # Generated: 2026-08-26 | Source: nixpkgs
  # Download Kotor (Full): 218.70 MiB | NAR: 8.14 MiB
  imagemagick = {
    storePath = "/nix/store/irnr8lky602v33p8042qp8y3xxa9lg61-imagemagick-7.1.2-29";
    version = "7.1.2-29";
    mainProgram = "magick";
    channel = "nixpkgs";
    system = "x86_64-linux";
  };
  # Generated: 2026-08-26 | Source: nixpkgs
  # Download Kotor (Full): 515.27 MiB | NAR: 164.97 MiB
  lsp_plugins = {
    storePath = "/nix/store/dj6246p871i5d6phxvjwv98ff8179gv7-lsp-plugins-1.2.29";
    version = "1.2.29";
    pname = "lsp-plugins";
    channel = "nixpkgs";
    system = "x86_64-linux";
  };

  # ── OCR, Scanning & Desktop Utilities (Batch A) ───────────────────────────
  # Generated: 2026-08-26 | Source: nixpkgs
  # Download Kotor (Full): 1105.68 MiB | NAR: 4.38 MiB
  tesseract = {
    storePath = "/nix/store/k7v448ggp0yii5blnp0ibgnyad3kdnzx-tesseract-5.5.2";
    version = "5.5.2";
    mainProgram = "tesseract";
    channel = "nixpkgs";
    system = "x86_64-linux";
  };
  # Generated: 2026-08-26 | Source: nixpkgs
  # Download Kotor (Full): 998.43 MiB | NAR: 5.86 MiB
  satty = {
    storePath = "/nix/store/wvdnv97ml3cfyj7b880rvjb0kapwjlbs-satty-0.20.1";
    version = "0.20.1";
    mainProgram = "satty";
    channel = "nixpkgs";
    system = "x86_64-linux";
  };
  # Generated: 2026-08-26 | Source: nixpkgs
  # Download Kotor (Full): 594.09 MiB | NAR: 0.25 MiB
  zbar = {
    storePath = "/nix/store/1jjdamf57jwd9dcp61xjzhhnqsrfl7cn-zbar-0.23.93";
    version = "0.23.93";
    mainProgram = "zbarimg";
    channel = "nixpkgs";
    system = "x86_64-linux";
  };
  # Generated: 2026-08-26 | Source: nixpkgs
  # Download Kotor (Full): 203.57 MiB | NAR: 0.19 MiB
  wl_clipboard = {
    storePath = "/nix/store/0kw6lhibiflzxrnv3rcpp3zn5i7vbrdq-wl-clipboard-2.3.0";
    version = "2.3.0";
    mainProgram = "wl-clipboard";
    channel = "nixpkgs";
    system = "x86_64-linux";
  };
  # Generated: 2026-08-26 | Source: nixpkgs
  # Download Kotor (Full): 1086.53 MiB | NAR: 0.32 MiB
  scrcpy = {
    storePath = "/nix/store/bsgqh30fyad6r1qswah6y6cwggq8971s-scrcpy-4.1";
    version = "4.1";
    mainProgram = "scrcpy";
    channel = "nixpkgs";
    system = "x86_64-linux";
  };
  # Generated: 2026-08-26 | Source: nixpkgs
  # Download Kotor (Full): 1001.46 MiB | NAR: 8.88 MiB
  zenity = {
    storePath = "/nix/store/4b9b1qp88gdpbim1l4fn7a3hfq1hw8gd-zenity-4.2.2";
    version = "4.2.2";
    mainProgram = "zenity";
    channel = "nixpkgs";
    system = "x86_64-linux";
  };
  # Generated: 2026-08-26 | Source: nixpkgs
  # Download Kotor (Full): 387.93 MiB | NAR: 7.70 MiB
  seahorse = {
    storePath = "/nix/store/6966njaxakigkxw9lyqjyf7ib67y756j-seahorse-47.0.1";
    version = "47.0.1";
    mainProgram = "seahorse";
    channel = "nixpkgs";
    system = "x86_64-linux";
  };

  # ── Storage & Cloud (Batch A) ─────────────────────────────────────────────
  # Generated: 2026-08-26 | Source: nixpkgs
  # Download Kotor (Full): 158.80 MiB | NAR: 106.37 MiB
  rclone = {
    storePath = "/nix/store/86nhn0hbzqww5s85573nyfw5ci1xc882-rclone-1.75.0";
    version = "1.75.0";
    mainProgram = "rclone";
    channel = "nixpkgs";
    system = "x86_64-linux";
  };
  # Generated: 2026-08-26 | Source: nixpkgs
  # Download Kotor (Full): 250.16 MiB | NAR: 48.17 MiB
  restic = {
    storePath = "/nix/store/j6gf70r6d1p0gng0wr18lvdgcgprynlk-restic-0.18.1";
    version = "0.18.1";
    mainProgram = "restic";
    channel = "nixpkgs";
    system = "x86_64-linux";
  };

  # ── Gaming & Emulators (Batch A) ──────────────────────────────────────────
  # Generated: 2026-08-26 | Source: nixpkgs
  retroarch_bare = {
    storePath = "/nix/store/nwjskxi9dxm7iv52712kjipk2mnll3if-retroarch-bare-1.22.2";
    version = "1.22.2";
    mainProgram = "retroarch";
    channel = "nixpkgs";
    system = "x86_64-linux";
  };
  # Generated: 2026-08-26 | Source: nixpkgs
  # Download Kotor (Full): 389.36 MiB | NAR: 6.57 MiB
  antimicrox = {
    storePath = "/nix/store/jgx2gy52scyv4afnwnplhzj705vg28r5-antimicrox-3.5.1";
    version = "3.5.1";
    mainProgram = "antimicrox";
    channel = "nixpkgs";
    system = "x86_64-linux";
  };

  # ── Heavy Runtimes & Toolchains (Large NAR Batch) ─────────────────────────
  # Generated: 2026-08-26 | Source: nixpkgs
  # Download Kotor (Full): 114.27 MiB | NAR: 65.44 MiB
  uv = {
    storePath = "/nix/store/lzg7xzpjhirf2a7msf2rlwv7dphj2fa2-uv-0.11.21";
    version = "0.11.21";
    mainProgram = "uv";
    channel = "nixpkgs";
    system = "x86_64-linux";
  };
  # Generated: 2026-08-26 | Source: nixpkgs
  # Download Kotor (Full): 200.17 MiB | NAR: 127.50 MiB
  python3 = {
    storePath = "/nix/store/xqnbm0vgqcq9b1b54c80qj9s0qhbwa08-python3-3.13.15";
    version = "3.13.15";
    mainProgram = "python3.13";
    channel = "nixpkgs";
    system = "x86_64-linux";
  };
  # Generated: 2026-08-26 | Source: nixpkgs
  # Download Kotor (Full): 222.53 MiB | NAR: 222.53 MiB
  nerd_fonts_jetbrains_mono = {
    storePath = "/nix/store/qmw1z6j4z3ja83cr3kx9azv3z56ads3m-nerd-fonts-jetbrains-mono-3.4.0+2.304";
    version = "3.4.0+2.304";
    pname = "nerd-fonts-jetbrains-mono";
    channel = "nixpkgs";
    system = "x86_64-linux";
  };
}
