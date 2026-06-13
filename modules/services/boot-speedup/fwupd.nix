{ config, lib, selfLib, ... }:

selfLib.mkModule {
  name = "services.boot-speedup.fwupd";
  nixosConfig = lib.mkIf config.my.services.boot-speedup.enable {
    services.fwupd.enable = lib.mkForce false;
    systemd.services.fwupd-refresh.enable = lib.mkForce false;
    systemd.timers.fwupd-refresh.enable = lib.mkForce false;
    systemd.services.fwupd.enable = lib.mkForce false;
  };
}
