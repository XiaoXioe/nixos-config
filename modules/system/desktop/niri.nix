{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.my.system.niri;
in
{
  options.my.system.niri = {
    enable = lib.mkEnableOption "niri Wayland compositor";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      nautilus
      kdePackages.gwenview
    ];

    programs.niri.enable = true;

  };
}
