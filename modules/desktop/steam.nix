{
  config,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.desktop.steam;
in
{
  options = selfLib.mkNestedEnable "desktop.steam";

  config = lib.mkIf cfg.enable {
    hardware.steam-hardware.enable = true;

    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };
  };
}
