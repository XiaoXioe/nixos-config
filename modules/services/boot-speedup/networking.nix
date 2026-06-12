{
  config,
  lib,
  selfLib,
  ...
}:

let
  cfg = config.my.services.boot-speedup;
  inherit (lib) mkIf;
in
{
  options = selfLib.mkNestedEnable "services.boot-speedup.networking";

  config = mkIf (cfg.enable && cfg.networking.enable) {
    systemd.services.NetworkManager-wait-online.enable = false;
    systemd.services.ModemManager.enable = false;
  };
}
