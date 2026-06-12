{
  config,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.security.networking;
in
{
  options = selfLib.mkNestedEnable "security.networking";

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

        # Disable Wi-Fi power saving in NetworkManager
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
