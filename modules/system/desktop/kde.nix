{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.my.system.desktop.kde;
in
{
  options.my.system.desktop.kde = {
    enable = lib.mkEnableOption "Kde Plasma configuration";
    unstable = lib.mkEnableOption "Use unstable packages for KDE";
  };

  config = lib.mkIf cfg.enable {

    nixpkgs.overlays = lib.mkIf cfg.unstable [
      (_final: _prev: {
        kdePackages = pkgs.kdePackages;
        qt6 = pkgs.qt6;
        # sddm = pkgs.sddm;
      })
    ];

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
