{
  config,
  lib,
  selfLib,
  ...
}:

let
  cfg = config.my.services.boot-speedup;
  inherit (lib) mkIf mkForce;
in
{
  options = selfLib.mkNestedEnable "services.boot-speedup.fwupd";

  config = mkIf (cfg.enable && cfg.fwupd.enable) {
    services.fwupd.enable = mkForce false;
    systemd.services.fwupd-refresh.enable = mkForce false;
    systemd.timers.fwupd-refresh.enable = mkForce false;
    systemd.services.fwupd.enable = mkForce false;
  };
}
