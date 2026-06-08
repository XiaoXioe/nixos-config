# Steam gaming platform configuration.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.system.desktop.steam;
in
{
  options.my.system.desktop.steam = {
    enable = lib.mkEnableOption "Steam gaming platform";
  };

  config = lib.mkIf cfg.enable {
    hardware.steam-hardware.enable = true;

    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };
  };
}
