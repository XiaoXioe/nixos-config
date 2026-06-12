{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.browsers.browser";
  description = "General Browser for Multi-user";

  hmConfig = {
    home.packages = with pkgs; [ google-chrome ];
    xdg.configFile = {
      "brave-flags.conf".text = "--password-store=gnome";
      "chrome-flags.conf".text = "--password-store=gnome";
      "chromium-flags.conf".text = "--password-store=gnome";
    };
  };
}
