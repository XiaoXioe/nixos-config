{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.user.apps.browser.browser;
in
{
  options.my.user.apps.browser.browser = {
    enable = lib.mkEnableOption "General Browser for Multi-user";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      google-chrome
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
