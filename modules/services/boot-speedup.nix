{
  lib,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "services.boot-speedup";

  nixosConfig = {
    # drkonqi

    # fwupd
    services.fwupd.enable = lib.mkForce false;

    # hardware
    services.printing.enable = false;
    hardware.bluetooth.enable = lib.mkForce false;

    # networking

    systemd = {
      services = {
        "drkonqi-coredump-processor@".enable = false;
        fwupd-refresh.enable = lib.mkForce false;
        NetworkManager-wait-online.enable = false;
        ModemManager.enable = false;
        "user@" = {
          serviceConfig = {
            TimeoutStopSec = "10s";
          };
        };
      };

      user = {
        services."drkonqi-coredump-launcher".enable = false;
        sockets."drkonqi-coredump-launcher" = {
          enable = false;
          wantedBy = lib.mkForce [ ];
        };
        extraConfig = ''
          DefaultTimeoutStopSec=10s
        '';
      };

      timers.fwupd-refresh.enable = lib.mkForce false;

      settings.Manager.DefaultTimeoutStopSec = "10s";
    };
  };
}
