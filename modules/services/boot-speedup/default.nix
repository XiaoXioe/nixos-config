{
  config,
  lib,
  selfLib,
  ...
}:

let
  cfg = config.my.services.boot-speedup;
in
{
  imports = selfLib.scanPaths ./.;

  options = selfLib.mkNestedEnable "services.boot-speedup";

  config = lib.mkIf (!cfg.enable) {
    my.services.boot-speedup = {
      networking.enable = lib.mkDefault false;
      hardware.enable = lib.mkDefault false;
      fwupd.enable = lib.mkDefault false;
      drkonqi.enable = lib.mkDefault false;
      systemd-timeout.enable = lib.mkDefault false;
    };
  };
}
