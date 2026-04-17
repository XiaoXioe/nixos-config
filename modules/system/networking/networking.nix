{
  config,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.system.networking;
in
{
  options.my.system.networking = {
    enable = selfLib.mkBoolOpt false "Firewall configuration";
  };

  config = lib.mkIf cfg.enable {
    networking = {
      firewall = {
        enable = true;
        allowPing = false;
        logRefusedConnections = true;
        trustedInterfaces = [
          "wg-lan"
          "wg-wifi"
          "waydroid0"
        ];
        checkReversePath = "loose";
        # filterForward = false;
      };

      networkmanager = {
        enable = true;
        # wifi.macAddress = "random";
        # ethernet.macAddress = "random";
        wifi.macAddress = "stable";
        ethernet.macAddress = "stable";

        # Mematikan power saving khusus untuk Wi-Fi di NetworkManager
        wifi = {
          powersave = false;
        };
      };

      nftables = {
        enable = true;
      };
      usePredictableInterfaceNames = false;
      enableIPv6 = false;
      useDHCP = false;
    };

  };
}
