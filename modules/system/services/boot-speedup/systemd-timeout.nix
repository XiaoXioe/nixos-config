{
  config,
  lib,
  ...
}:

let
  cfg = config.my.system.services.bootSpeedup;
  inherit (lib) mkIf;
in
{
  options.my.system.services.bootSpeedup.systemdTimeout = {
    enable = lib.mkEnableOption "set DefaultTimeoutStopSec to 10s" // {
      default = true;
    };
  };

  config = mkIf (cfg.enable && cfg.systemdTimeout.enable) {
    systemd.settings.Manager.DefaultTimeoutStopSec = "10s";
  };
}
