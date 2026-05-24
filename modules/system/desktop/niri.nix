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
      nautilus
      kdePackages.gwenview
    ];

    programs.niri.enable = true;

  };
}
