{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.system.kde;
in
{
  options.my.system.kde = {
    enable = selfLib.mkBoolOpt false "Kde Plasma configuration";
  };

  config = lib.mkIf cfg.enable {
    # Mengaktifkan modul i2c untuk kontrol monitor eksternal
    hardware.i2c.enable = true;

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
      # kwallet
      # kwallet-pam
      kwalletmanager
    ];

    environment.systemPackages = with pkgs; [
      sddm-sugar-dark
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
