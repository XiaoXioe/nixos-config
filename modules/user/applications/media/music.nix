{
  config,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.user.music;
in
{
  options.my.user.music = {
    enable = selfLib.mkBoolOpt false "Music player configuration ";
  };

  config = lib.mkIf cfg.enable {
    programs.cmus = {
      enable = true;
      theme = "gruvbox";
      extraConfig = ''
        # === Pengaturan Bawaan Anda ===
        set resume=true

        # === Audio Backend (Pipewire / PulseAudio) ===
        # Memaksa cmus menggunakan backend pulse (kompatibel dengan Pipewire).
        # Ini mencegah error "Device or resource busy" jika aplikasi lain sedang memutar audio.
        set output_plugin=pulse

        # === Quality of Life & Pemutaran ===
        # Menormalisasi volume agar lagu lama dan baru tidak memiliki lonjakan suara yang mengagetkan
        set replaygain=track
        # Secara otomatis memainkan lagu berikutnya di *library* (bukan hanya di *playlist*)
        set play_library=true
        set play_sorted=true
        # Memutar ulang dari awal saat lagu terakhir di daftar selesai
        set repeat=true

        # === Tampilan & Format ===
        # Menampilkan waktu sisa lagu secara default (alih-alih waktu yang sudah berlalu)
        set show_remaining_time=true
        # Memformat bilah status bawah agar lebih rapi
        set status_display_program=

      '';
    };
  };
}
