{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.my.user.game;
in
{
  options.my.user.game = {
    enable = lib.mkEnableOption "User game settings";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      # lutris
      xwayland-satellite # jembatan aplikasi X11
      ppsspp
      pcsx2
    ];

    home.sessionVariables = {
      SDL_GAMECONTROLLERCONFIG = "03000000790000000600000010010000,Microntek USB Joystick,crc:79be,platform:Linux,a:b2,b:b1,x:b3,y:b0,dpleft:h0.8,dpright:h0.2,dpup:h0.1,dpdown:h0.4,leftx:a0,lefty:a1,leftstick:b10,rightx:a2,righty:a3,rightstick:b11,leftshoulder:b4,lefttrigger:b6,rightshoulder:b5,righttrigger:b7,back:b8,start:b9,steam:2,";
    };

    programs.retroarch = {
      enable = true;

      # Mengisi RetroArch dengan core (emulator) pilihan
      cores = {
        # --- Era Klasik 2D ---
        nestopia.enable = true;
        snes9x.enable = true;
        "genesis-plus-gx".enable = true; # Gunakan tanda kutip karena ada strip (-)
        mgba.enable = true;

        # --- Era 3D Awal ---
        mupen64plus.enable = true;
        swanstation.enable = true;

        # --- Generasi Lanjutan ---
        ppsspp.enable = true;
        pcsx2.enable = true;
      };

      settings = {
        "video_driver" = "gl";
        "audio_driver" = "pulse"; # Standar audio untuk NixOS (PipeWire)
        "input_joypad_driver" = "udev"; # Sangat baik untuk deteksi otomatis gamepad (stik) di Linux
        "fps_show" = "true";
        "menu_swap_ok_cancel_buttons" = "true";

        # --- Pengaturan Hotkey Menu ---
        "input_menu_toggle_gamepad_combo" = "4";

        # --- Optimasi Performa iGPU ---
        # Memisahkan pemrosesan video ke thread CPU yang berbeda.
        # Sangat esensial untuk mencegah FPS drop atau patah-patah pada game 3D (seperti PS1)
        # saat sistem tidak menggunakan kartu grafis diskrit.
        "video_threaded" = "true";

        # --- Quality of Life (Kenyamanan) ---
        # Wajib menekan tombol keluar (biasanya ESC di keyboard) dua kali.
        # Mencegah Anda tidak sengaja mematikan game yang sedang seru dimainkan.
        "quit_press_twice" = "true";

        # Otomatis melakukan "Save State" tepat di detik terakhir sebelum Anda menutup RetroArch.
        "savestate_auto_save" = "true";

        # Otomatis memuat "Save State" tersebut saat game dibuka kembali.
        # Anda bisa langsung melanjutkan permainan tanpa harus melihat layar loading BIOS PS1 lagi.
        "savestate_auto_load" = "true";

        # --- Notifikasi ---
        # Menyembunyikan teks kuning yang sering muncul berulang-ulang
        # di pojok kiri bawah saat mencolokkan/mencabut stik USB.
        "notification_show_autoconfig" = "false";
      };
    };
  };
}
