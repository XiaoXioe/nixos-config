{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "desktop.xfce";

  nixosConfig = {
    services.xserver.enable = true;
    services.xserver.desktopManager.xfce.enable = true;

    environment.systemPackages = with pkgs; [
      xfce4-pulseaudio-plugin
      xfce4-whiskermenu-plugin
      xfce4-battery-plugin

    ];
  };
}
