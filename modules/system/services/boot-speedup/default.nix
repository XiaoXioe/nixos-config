{
  config,
  lib,
  selfLib,
  ...
}:

let
  cfg = config.my.system.services.bootSpeedup;
in
{
  imports = selfLib.scanPaths ./.;

  options.my.system.services.bootSpeedup = {
    enable = lib.mkEnableOption "systemd boot speedup optimizations";
  };

  config = lib.mkIf (!cfg.enable) {
    my.system.services.bootSpeedup = {
      networking.enable = lib.mkDefault false;
      hardware.enable = lib.mkDefault false;
      fwupd.enable = lib.mkDefault false;
      drkonqi.enable = lib.mkDefault false;
      systemdTimeout.enable = lib.mkDefault false;
    };
  };
}
