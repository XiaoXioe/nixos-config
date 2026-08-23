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
#   ./scripts/query-cache-pin pkgs.rclone
#   ./scripts/query-cache-pin pkgs.mpv
#   ./scripts/query-cache-pin pkgs.syncthing
#   → copy output ke file ini
#
# Cara update versi (misal rclone naik versi):
#   ./scripts/query-cache-pin pkgs.rclone
#   → ganti storePath lama dengan output baru
#   (path lama tetap di /nix/store sampai nix-collect-garbage)
{
  # ── CLI Tools ─────────────────────────────────────────────────────────────

  # Generated: 2026-08-23 | nixpkgs/nixos-26.05
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

  # ── Tambah entri lain dengan: ./scripts/query-cache-pin pkgs.<name> ───────
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
