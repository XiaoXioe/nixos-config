{
  config,
  lib,
  selfLib,
  ...
}:

let
  cfg = config.my.services.nm-speedup;
in
{
  options.my.services.nm-speedup = {
    enable = selfLib.mkBoolOpt false "Speedup booting with disable some services";
  };

  config = lib.mkIf cfg.enable {
    systemd.services.NetworkManager-wait-online.enable = false;
    systemd.services.ModemManager.enable = false;
    services.fwupd.enable = false;
    services.printing.enable = false;

    # Mematikan pelapor crash KDE secara paksa agar tidak bentrok dengan Niri
    systemd.user.services."drkonqi-coredump-launcher@".enable = false;
    systemd.user.services."drkonqi-coredump-processor@".enable = false;

    hardware.bluetooth.enable = lib.mkForce false;
  };
}
