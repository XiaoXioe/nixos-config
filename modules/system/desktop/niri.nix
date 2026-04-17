{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.system.niri;
in
{
  options.my.system.niri = {
    enable = selfLib.mkBoolOpt false "niri Wayland compositor";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      swaylock
      swayidle
      nautilus
      gnome-terminal
      kdePackages.gwenview
    ];

    programs.niri.enable = true;
    hardware.i2c.enable = true;

  };
}
