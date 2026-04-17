{
  config,
  lib,
  pkgs,
  selfLib,
  ...
}:

let
  cfg = config.my.user.browser;
in
{
  options.my.user.browser = {
    enable = selfLib.mkBoolOpt false "General Browser for Multi-user";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      google-chrome
      librewolf
    ];

    xdg.configFile = {
      "brave-flags.conf".text = "--password-store=gnome";
      "chrome-flags.conf".text = "--password-store=gnome";
      "chromium-flags.conf".text = "--password-store=gnome";
      # "vivaldi-flags.conf".text = "--password-store=gnome";
      # "edge-flags.conf".text = "--password-store=gnome";
    };
  };
}
