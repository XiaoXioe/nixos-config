{
  pkgs,
  inputs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "desktop.hyprland";
  description = "Hyprland window manager with Caelestia Shell";

  nixosConfig = {
    # Enable Hyprland in NixOS
    programs.hyprland = {
      enable = true;
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
  };

  hmConfig = {
    imports = [
      inputs.caelestia-shell.homeManagerModules.default
      ./caelestia.nix
      ./settings.nix
      ./keybind.nix
    ];
  };
}
