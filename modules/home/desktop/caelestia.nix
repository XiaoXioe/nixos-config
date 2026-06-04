{
  config,
  lib,
  pkgs,
  inputs,
  flakePath,
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
    enable = lib.mkEnableOption "Caelestia shell for Hyprland";
  };

  config = lib.mkIf cfg.enable {
    programs.caelestia = {
      enable = true;
      package = inputs.caelestia-shell.packages.${pkgs.stdenv.hostPlatform.system}.with-cli;

      # Pastikan Caelestia start saat masuk ke sesi grafis (Hyprland via UWSM)
      systemd.target = "graphical-session.target";
    };

    # Tambahkan kondisi agar service Caelestia hanya benar-benar jalan di Hyprland
    systemd.user.services.caelestia = {
      Unit.ConditionEnvironment = "HYPRLAND_INSTANCE_SIGNATURE";
    };

    # Link konfigurasi Caelestia
    xdg.configFile."caelestia/shell.json".source =
      config.lib.file.mkOutOfStoreSymlink "${flakePath}/modules/home/conf/caelestia/shell.json";
  };
}
