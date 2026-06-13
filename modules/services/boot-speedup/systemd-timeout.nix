{
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "services.boot-speedup.systemd-timeout";

  nixosConfig = {
    # Only apply if the parent boot-speedup is also enabled
    systemd.settings.Manager.DefaultTimeoutStopSec = "10s";
  };
}
