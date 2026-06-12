{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.desktop.niri;
in
{
  options = selfLib.mkNestedEnable "desktop.niri";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      nautilus
      kdePackages.gwenview
    ];

    programs.niri.enable = true;
  };
}
