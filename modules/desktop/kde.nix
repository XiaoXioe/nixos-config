{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:
selfLib.mkModule {
  name = "desktop.kde";
  nixosConfig = {
    services.xserver.enable = true;
    services.desktopManager.plasma6.enable = true;

    environment.plasma6.excludePackages = with pkgs.kdePackages; [
      discover
      baloo
      baloo-widgets
      plasma-browser-integration
      kinfocenter
      drkonqi
      kate
      oxygen
      print-manager
      elisa
      okular
      kuserfeedback
      krdp
      khelpcenter
      plasma-workspace-wallpapers
      kwallet
      kwallet-pam
      kwalletmanager
    ];

    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };
  };
}
