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
      capabilities = "cap_net_raw,cap_net_admin+ep";
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

        dispatcherScripts = [
          {
            source = pkgs.writeShellScript "vpn-killswitch" ''
              INTERFACE=$1
              ACTION=$2

              if [[ "$INTERFACE" =~ ^proton- || "$INTERFACE" == "wg-warp" ]]; then
                case "$ACTION" in
                  up|vpn-up)
                    # Aktifkan killswitch: blokir traffic keluar lewat interface fisik
                    ${pkgs.nftables}/bin/nft add rule inet filter vpn_killswitch oifname eth* drop
                    ${pkgs.nftables}/bin/nft add rule inet filter vpn_killswitch oifname wlan* drop
                    ${pkgs.nftables}/bin/nft add rule inet filter vpn_killswitch oifname wlp* drop
                    ;;
                  down|vpn-down)
                    # Matikan killswitch: hapus aturan blokir
                    ${pkgs.nftables}/bin/nft flush chain inet filter vpn_killswitch
                    ;;
                esac
              fi
            '';
            type = "basic";
          }
        ];
      };

      nftables = {
        enable = true;
        ruleset = ''
          table inet filter {
            chain output {
              type filter hook output priority filter; policy accept;

              # 1. Izinkan loopback
              oifname "lo" accept

              # 2. Izinkan akses LAN lokal
              ip daddr { 127.0.0.0/8, 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 } accept

              # 3. Izinkan handshake WireGuard ke luar
              udp dport { 500, 4500, 51820, 50820 } accept

              # 4. Lompat ke chain killswitch dinamis
              jump vpn_killswitch
            }

            chain vpn_killswitch {
              # Dikelola dinamis oleh dispatcher script NetworkManager
            }
          }
        '';
      };
      usePredictableInterfaceNames = false;
      enableIPv6 = false;
      useDHCP = false;
    };
  };
}
