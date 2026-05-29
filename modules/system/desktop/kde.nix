{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.my.system.kde;
in
{
  options.my.system.kde = {
    enable = lib.mkEnableOption "Kde Plasma configuration";
    unstable = lib.mkEnableOption "Use unstable packages for KDE";
  };

  config = lib.mkIf cfg.enable {

    nixpkgs.overlays = lib.mkIf cfg.unstable [
      (final: prev: {
        kdePackages = pkgs.kdePackages;
        qt6 = pkgs.qt6;
        # sddm = pkgs.sddm;
      })
    ];

    services.xserver.enable = true;

    services.desktopManager.plasma6.enable = true;

    environment.plasma6.excludePackages = with pkgs.kdePackages; [
      discover
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

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };
}
