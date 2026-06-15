{
  config,
  lib,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "services.boot-speedup";

  nixosConfig = {
    # drkonqi
    systemd.services."drkonqi-coredump-processor@".enable = false;
    systemd.user.sockets."drkonqi-coredump-launcher".enable = false;
    systemd.user.services."drkonqi-coredump-launcher".enable = false;

    # fwupd
    services.fwupd.enable = lib.mkForce false;
    systemd.services.fwupd-refresh.enable = lib.mkForce false;
    systemd.timers.fwupd-refresh.enable = lib.mkForce false;
    systemd.services.fwupd.enable = lib.mkForce false;

    # hardware
    services.printing.enable = false;
    hardware.bluetooth.enable = lib.mkForce false;

    # networking
    systemd.services.NetworkManager-wait-online.enable = false;
    systemd.services.ModemManager.enable = false;

    # systemd-timeout
    systemd.settings.Manager.DefaultTimeoutStopSec = "10s";
  };
}
