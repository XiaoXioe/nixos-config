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
  options = selfLib.mkNestedEnable "services.boot-speedup.systemd-timeout";

  config = lib.mkIf (config.my.services.boot-speedup.enable && cfg.systemd-timeout.enable) {
    systemd.settings.Manager.DefaultTimeoutStopSec = "10s";
  };
}
