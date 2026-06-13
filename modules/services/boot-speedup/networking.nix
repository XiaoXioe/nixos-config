{
  config,
  lib,
  ...
}:

{
  config = lib.mkIf config.my.services.boot-speedup.enable {
    systemd.services.NetworkManager-wait-online.enable = false;
    systemd.services.ModemManager.enable = false;
  };
}
