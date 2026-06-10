{
  config,
  lib,
  ...
}:

let
  cfg = config.my.system.services.nm-speedup;
in
{
  options.my.system.services.nm-speedup = {
    enable = lib.mkEnableOption "Speedup booting with disable some services";
  };

  config = lib.mkIf cfg.enable {
    systemd.services.NetworkManager-wait-online.enable = false;
    systemd.services.ModemManager.enable = false;
    services.printing.enable = false;

    # Mematikan pelapor crash KDE secara paksa agar tidak bentrok dengan Niri
    systemd.user.services."drkonqi-coredump-launcher@".enable = false;
    systemd.user.services."drkonqi-coredump-processor@".enable = false;

    hardware.bluetooth.enable = lib.mkForce false;

    # To prevent getting stuck at shutdown
    systemd.settings.Manager.DefaultTimeoutStopSec = "10s";

    # Menonaktifkan modul utama fwupd
    services.fwupd.enable = lib.mkForce false;

    # MASKING: Memblokir total service agar tidak bisa dipanggil oleh apapun
    systemd.services.fwupd-refresh.mask = true;
    systemd.timers.fwupd-refresh.mask = true;
    systemd.services.fwupd.mask = true;
  };
}
