{
  inputs,
  selfLib,
  lib,
  ...
}:

selfLib.mkModule {
  name = "desktop.niri";
  description = "Niri scrollable-tiling Wayland compositor";

  options = {
    dms = {
      enable = lib.mkEnableOption "DankMaterialShell for Niri";
    };
    noctalia = {
      enable = lib.mkEnableOption "Noctalia shell for Niri";
    };
  };

  imports = [
    inputs.niri.nixosModules.niri
    ./sessions.nix
  ];

  nixosConfig =
    { pkgs, config, ... }:
    {
      programs.niri.enable = true;
      programs.niri.package = pkgs.niri;

      # Auto-wire shell options to modular shells
      my.desktop.shells.dms.enable = lib.mkIf (config.my.desktop.niri.dms.enable or false) true;
      my.desktop.shells.noctalia.enable = lib.mkIf (config.my.desktop.niri.noctalia.enable or false) true;
    };

  hmConfig = {
    imports = selfLib.scanPaths ./settings;
  };
}
