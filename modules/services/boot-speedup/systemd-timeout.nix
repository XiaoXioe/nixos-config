{
  config,
  lib,
  ...
}:

{
  config = lib.mkIf config.my.services.boot-speedup.enable {
    # Only apply if the parent boot-speedup is also enabled
    systemd.settings.Manager.DefaultTimeoutStopSec = "10s";
  };
}
