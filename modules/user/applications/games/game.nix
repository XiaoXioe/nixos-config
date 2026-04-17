{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:

let
  cfg = config.my.user.game;
in
{
  options.my.user.game = {
    enable = selfLib.mkBoolOpt false "user media configuration (mpv, yt-dlp)";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      lutris
      xwayland-satellite # jembatan aplikasi X11
      steam
      ppsspp
      pcsx2
    ];

    home.sessionVariables = {
      SDL_GAMECONTROLLERCONFIG = "03000000de280000ff11000001000000,Steam Virtual Gamepad,a:b0,b:b1,back:b6,dpdown:h0.4,dpleft:h0.8,dpright:h0.2,dpup:h0.1,guide:b8,leftshoulder:b4,leftstick:b9,lefttrigger:a2,leftx:a0,lefty:a1,rightshoulder:b5,rightstick:b10,righttrigger:a5,rightx:a3,righty:a4,start:b7,x:b2,y:b3,platform:Linux,";
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
      };
    };
  };
}
