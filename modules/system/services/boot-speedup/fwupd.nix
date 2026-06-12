{
  config,
  lib,
  ...
}:

let
  cfg = config.my.system.services.bootSpeedup;
  inherit (lib) mkIf mkForce;
in
{
  options.my.system.services.bootSpeedup.fwupd = {
    enable = lib.mkEnableOption "disable fwupd service, timer, and refresh" // {
      default = true;
    };
  };

  config = mkIf (cfg.enable && cfg.fwupd.enable) {
    services.fwupd.enable = mkForce false;
    systemd.services.fwupd-refresh.enable = mkForce false;
    systemd.timers.fwupd-refresh.enable = mkForce false;
    systemd.services.fwupd.enable = mkForce false;
  };
}
