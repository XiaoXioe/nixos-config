{
  pkgs,
  selfLib,
  ...
}:
selfLib.mkModule {
  name = "desktop.kde";
  nixosConfig = {
    services.xserver.enable = true;
    services.desktopManager.plasma6.enable = true;

    environment.variables = {

      # QT_QPA_PLATFORMTHEME diset per-DE di modul masing-masing
      # (niri.nix pakai "kde", KDE Plasma sudah handle sendiri)
      PLASMA_USE_QT_SCALING = "1";
      GSK_RENDERER = "gl";

      # Force KDE apps to terminate immediately on crash,
      # tanpa mencoba memanggil GUI pelapor crash
      KCRASH_CORE_PATTERN_RAISE = "1";
    };

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
