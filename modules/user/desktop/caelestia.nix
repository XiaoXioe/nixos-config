{
  config,
  lib,
  pkgs,
  selfLib,
  inputs,
  ...
}:
let
  cfg = config.my.user.caelestia;
in
{
  imports = [
    inputs.caelestia-shell.homeManagerModules.default
  ];

  options.my.user.caelestia = {
    enable = selfLib.mkBoolOpt false "Caelestia-shell untuk Hyprland";
  };

  config = lib.mkIf cfg.enable {
    programs.caelestia = {
      enable = true;
      #       package = inputs.caelestia-shell.packages.${pkgs.stdenv.hostPlatform.system}.with-cli.override {                                                                                          │
      #       quickshell = pkgs.quickshell;                                                                                                                                                           │
      #    };
      package = inputs.caelestia-shell.packages.${pkgs.stdenv.hostPlatform.system}.with-cli;

      # Pastikan Caelestia hanya start saat masuk ke Hyprland
      systemd.target = "hyprland-session.target";
    };
  };
}
