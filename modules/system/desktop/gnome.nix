{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.system.gnome;
in
{
  options.my.system.gnome = {
    enable = selfLib.mkBoolOpt false "GNOME desktop environment";
  };

  config = lib.mkIf cfg.enable {
    services.xserver.enable = true;

    services.desktopManager.gnome.enable = true;

    services.gnome.gnome-keyring.enable = true;
    security.pam.services.gdm.enableGnomeKeyring = true;

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
      gnome-connections
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
      gnome-terminal
      gnomeExtensions.vitals
      gnome-extension-manager
      gnomeExtensions.appindicator
      gnomeExtensions.dash-to-dock
      gnomeExtensions.blur-my-shell
      gnomeExtensions.just-perfection

      # (catppuccin-sddm.override {
      #   flavor = "mocha"; # latte / frappe / macchiato / mocha
      #   accent = "blue"; # blue / lavender / mauve / pink / red / etc.
      #   # background = ./wallpaper.jpg;   # opsional, taruh file di folder config
      # })
    ];

    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };

    # Wajib agar udev rule-nya jalan (penting!)
    services.udev.packages = with pkgs; [
      gnome-settings-daemon
    ];

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };
}
