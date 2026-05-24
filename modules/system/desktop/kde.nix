{
  config,
  pkgs,
  lib,
  selfLib,
  pkgsUnstable,
  ...
}:
let
  cfg = config.my.system.kde;
in
{
  options.my.system.kde = {
    enable = selfLib.mkBoolOpt false "Kde Plasma configuration";
    unstable = selfLib.mkBoolOpt false "Use unstable packages for KDE";
  };

  config = lib.mkIf cfg.enable {

    nixpkgs.overlays = lib.mkIf cfg.unstable [
      (final: prev: {
        kdePackages = pkgsUnstable.kdePackages;
        qt6 = pkgsUnstable.qt6;
        # sddm = pkgsUnstable.sddm;
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
