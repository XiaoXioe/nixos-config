{
  pkgs,
  selfLib,
  lib,
  ...
}:

selfLib.mkModule {
  name = "desktop.gnome";

  nixosConfig = {
    services.xserver.enable = true;

    services.desktopManager.gnome.enable = true;
    services.speechd.enable = lib.mkForce false;

    environment.gnome.excludePackages = with pkgs; [
      gnome-tour
      gnome-connections
      gnome-maps
      gnome-software
      gnome-logs
      gnome-music
      gnome-text-editor
      epiphany
      gnome-photos
      geary
      evince
      snapshot
      loupe
      totem
      decibels
      amberol
      gnome-console
      gnome-contacts
      simple-scan
      gnome-system-monitor
      baobab
      gnome-font-viewer
      gnome-characters
      gnome-remote-desktop
      yelp
      showtime
      papers
    ];

    environment.systemPackages = with pkgs; [
      gnome-tweaks
      gnomeExtensions.vitals
      gnome-extension-manager
      gnomeExtensions.appindicator
      gnomeExtensions.dash-to-dock
      gnomeExtensions.blur-my-shell
      gnomeExtensions.just-perfection
    ];

    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };

    services.gnome.gnome-online-accounts.enable = lib.mkForce false;
    services.avahi.enable = lib.mkForce false;

    services.udev.packages = with pkgs; [
      gnome-settings-daemon
    ];
  };
}
