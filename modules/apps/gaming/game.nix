{
  pkgs,
  selfLib,
  ...
}:
let
  niriGameRes = pkgs.writeShellScriptBin "niri-game-res" ''
    set -euo pipefail
    CURRENT=$(niri msg outputs | ${pkgs.gnugrep}/bin/grep "Current mode:" | ${pkgs.gawk}/bin/awk '{print $3}')
    if [ "$CURRENT" = "1280x720" ]; then
      niri msg output HDMI-A-1 mode 1680x1050@59.954
      ${pkgs.libnotify}/bin/notify-send -a "Gaming Mode" -t 2500 "Resolusi Harian Aktif" "HDMI-A-1: 1680x1050 @ 60Hz" || true
      echo "Resolusi dikembalikan ke mode harian: 1680x1050@59.954"
    else
      niri msg output HDMI-A-1 mode 1280x720@60.000
      ${pkgs.libnotify}/bin/notify-send -a "Gaming Mode" -t 2500 "Resolusi Gaming Aktif" "HDMI-A-1: 1280x720 @ 60Hz (Hemat ~48% beban GPU)" || true
      echo "Resolusi diubah ke mode performa gaming: 1280x720@60.000"
    fi
  '';
in
selfLib.mkModule {
  name = "apps.gaming.game";
  description = "User game settings (controllers and system integrations)";

  nixosConfig =
    { config, ... }:
    {
      hardware.uinput.enable = true;
      services.udev.packages = [ pkgs.game-devices-udev-rules ];

      users.users.${config.my.user.name}.extraGroups = [ "gamemode" ];

      programs.gamemode = {
        enable = true;
        # Nonaktifkan renice di gamemode karena sudah ditangani oleh ananicy-cpp (rules CachyOS)
        enableRenice = false;
        settings = {
          general = {
            renice = 0;
            ioprio = "off";
            defaultgov = "schedutil";
            desiredgov = "performance";
            inhibit_screensaver = 1;
          };
        };
      };
    };

  hmConfig = {
    home.packages = with pkgs; [
      xwayland-satellite
      niriGameRes
    ];
    home.sessionVariables = {
      SDL_GAMECONTROLLERCONFIG = "03000000790000000600000010010000,Microntek USB Joystick,crc:79be,platform:Linux,a:b2,b:b1,x:b3,y:b0,dpleft:h0.8,dpright:h0.2,dpup:h0.1,dpdown:h0.4,leftx:a0,lefty:a1,leftstick:b10,rightx:a2,righty:a3,rightstick:b11,leftshoulder:b4,lefttrigger:b6,rightshoulder:b5,righttrigger:b7,back:b8,start:b9,steam:2,";
    };
  };
}
