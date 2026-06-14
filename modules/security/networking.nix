{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "security.networking";

  nixosConfig = {

    environment.systemPackages = with pkgs; [
      wireguard-tools
      iproute2
      openresolv

    ];

    security.wrappers = {
      nethogs = {
        source = "${pkgs.nethogs}/bin/nethogs";
        capabilities = "cap_net_admin,cap_net_raw+ep";
        owner = "root";
        group = "root";
      };
    };

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
