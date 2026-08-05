{
  pkgs,
  inputs,
  selfLib,
  lib,
  ...
}:

selfLib.mkModule {
  name = "desktop.hyprland";
  description = "Hyprland window manager with Caelestia Shell";

  imports = [
    ./nandoroid
  ];

  nixosConfig = {
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
  };

  hmConfig = hmOpts: {
    imports =
      (selfLib.scanPaths ./settings)
      ++ (selfLib.scanPaths ./keybinds)
      ++ lib.optionals (inputs ? caelestia-shell && !hmOpts.config.my.desktop.hyprland.nandoroid.enable) (
        [
          inputs.caelestia-shell.homeManagerModules.default
        ]
        ++ (selfLib.scanPaths ./caelestia)
      );
  };
}
