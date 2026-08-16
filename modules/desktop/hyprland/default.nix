{
  pkgs,
  selfLib,
  lib,
  ...
}:

selfLib.mkModule {
  name = "desktop.hyprland";
  description = "Hyprland Wayland compositor";

  options = {
    noctalia = {
      enable = lib.mkEnableOption "Noctalia shell for Hyprland";
    };
  };

  nixosConfig =
    { config, ... }:
    {
      # Enable Hyprland in NixOS
      programs.hyprland = {
        enable = true;
        withUWSM = true;
      };

      # System-level dependencies for Wayland/Hyprland
      security.pam.services.hyprlock = { };
      services.dbus.enable = true;

      # XDG portal setup
      xdg.portal = {
        enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      };

      # Additional utility tools
      environment.systemPackages = with pkgs; [
        wl-clipboard
        grim
        slurp
        swappy
      ];

      # Auto-wire shell options to modular shells
      my.desktop.shells.noctalia.enable = lib.mkIf (config.my.desktop.hyprland.noctalia.enable or false
      ) true;
    };

  hmConfig = {
    imports = [
      ./settings.nix
      ./keybinds.nix
    ];
  };
}
