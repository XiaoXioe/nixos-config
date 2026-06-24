# To-Do List & Status Tugas

## Tugas yang Selesai
- [x] Migrasi AyuGram ke Flatpak menggunakan helper `mkApp` di `modules/apps/media/sosmed.nix`.
- [x] Perbaikan instalasi custom bundle `.flatpak` non-Flathub pada `lib/modules.nix` (penanganan format set `{ appId, bundle, sha256 }`).
- [x] Pencegahan nested symlinks pada skrip aktivasi Home Manager di `lib/modules.nix` (penghapusan otomatis direktori biasa sebelum pembuatan symlink).
- [x] Pembaruan Workspace Rules di `.agents/AGENTS.md` untuk mencakup pelajaran dari perbaikan ini.
- [x] Menghubungkan data lama (*host profile directories*) untuk setiap aplikasi sosial media di `sosmed.nix` yang menggunakan Flatpak (AyuGram, Discord, Signal, TradingView, dan Ente Auth) agar datanya sinkron.
- [x] Memecah berkas `lib/modules.nix` menjadi sub-modul terpisah di dalam folder `lib/modules/` agar strukturnya lebih rapi.
- [x] Migrasi `office.nix` ke model modular berbasis `selfLib.mkModule` dan `selfLib.mkApp`.
- [x] Membersihkan/merapikan status git commit yang dirty di repositori `nixos-config`.
- [x] Migrasi peramban (`chromium.nix`, `librewolf.nix`, dan `firefox.nix`) di bawah `modules/apps/browsers/` ke model Flatpak menggunakan helper `selfLib.mkApp`.
- [x] Pemulihan dan pembersihan direktori profil Firefox asli di host (`~/.config/mozilla/firefox/`) serta pencegahan symlink melingkar pada guest sandbox path (`.mozilla/firefox`).
- [x] Pembebasan branch lock pada `feature/flatpak-browsers` (penghapusan sisa worktree subagent) dan penggabungan (merge) branch secara bersih ke `main` menggunakan `--no-ff`.

## Tugas Selanjutnya
- [ ] Meminta Klein melakukan rebuild sistem secara lokal (`nh os test` atau `nh os switch`) untuk mengaktifkan konfigurasi peramban Flatpak baru.
- [ ] Menunggu umpan balik dari Klein mengenai fungsionalitas peramban Flatpak (Firefox, Chromium, LibreWolf) dan deteksi profil lama mereka.
- [ ] Mengevaluasi modul aplikasi lain di bawah `modules/apps/` untuk migrasi potensial ke Flatpak jika diperlukan demi keamanan dan isolasi sandbox.
