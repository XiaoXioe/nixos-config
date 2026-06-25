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

    security.wrappers.bandwhich = {
      source = "${pkgs.bandwhich}/bin/bandwhich";
      owner = "root";
      group = "root";
      capabilities = "cap_sys_ptrace,cap_dac_read_search,cap_net_raw,cap_net_admin+ep";
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
