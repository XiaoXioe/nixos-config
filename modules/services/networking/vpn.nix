{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:

let
  vpnDir = ./vpn-files;
  vpnFiles = selfLib.getVpnFiles vpnDir;
  protonVpnFiles = builtins.filter (x: x != "wg-warp.conf") vpnFiles;
in
selfLib.mkModule {
  name = "services.networking.vpn";
  description = "WireGuard VPN service and CLI control scripts (wireproxy)";

  nixosConfig = {
    networking.networkmanager.enable = true;

    sops.secrets = lib.mkMerge [
      (builtins.listToAttrs (
        map
          (iface: {
            name = "wg-${iface}.conf";
            value = {
              sopsFile = ./vpn-files + "/wg-${iface}.enc.conf";
              format = "binary";
              path = "/etc/wireguard/wg-${iface}.conf";
              owner = "root";
              group = "root";
              mode = "0600";
            };
          })
          [
            "lan"
            "wifi"
          ]
      ))
      (lib.listToAttrs (
        map (fileName: {
          name = fileName;
          value = {
            sopsFile = ./. + "/vpn-files/${fileName}";
            format = "binary";
            owner = config.my.user.name;
            mode = "0600";
          };
        }) vpnFiles
      ))
    ];

    # ProtonVPN sebagai Flatpak — diinstal bersama modul VPN
    services.flatpak.packages = [ "com.protonvpn.www" ];

    systemd.services.nm-import-proton = {
      description = "Auto import VPNs to NetworkManager";
      after = [
        "NetworkManager.service"
        "sops-nix.service"
      ];
      wants = [ "NetworkManager.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
      script = ''
        ${lib.concatMapStringsSep "\n" (fileName: ''
          VPN_ID="${lib.removeSuffix ".conf" fileName}"

          if ! ${pkgs.networkmanager}/bin/nmcli connection show "$VPN_ID" > /dev/null 2>&1; then
            ${pkgs.networkmanager}/bin/nmcli connection import type wireguard file ${
              config.sops.secrets.${fileName}.path
            }

            # nmcli assigns connection ID based on the file basename
            ${pkgs.networkmanager}/bin/nmcli connection modify "$VPN_ID" connection.autoconnect no wireguard.fwmark 51820 || true
          fi
        '') vpnFiles}
      '';
    };
  };

  hmConfig =
    hmOpts:
    let
      vpnPaths = pkgs.lib.concatMapStringsSep " " (
        f: "\"${hmOpts.osConfig.sops.secrets."${f}".path}\""
      ) protonVpnFiles;

      vpn-off-bin = selfLib.mkApp pkgs "vpn-off-bin" ''
        if [ -f ~/.cache/vpn/pid ]; then
            WIREPROXY_PID=$(cat ~/.cache/vpn/pid)
            kill "$WIREPROXY_PID" 2>/dev/null
            rm -f ~/.cache/vpn/pid ~/.cache/vpn/active_name
        else
            ${pkgs.procps}/bin/pkill -u "$(id -u)" -x wireproxy 2>/dev/null
        fi
        echo "❌ Wireproxy dimatikan. Terminal kembali ke IP asli."
      '' [ ];

      vpn-on-bin = selfLib.mkApp pkgs "vpn-on-bin" ''
        # Cek apakah wireproxy milik user ini sudah berjalan
        if ${pkgs.procps}/bin/pgrep -u "$(id -u)" -x wireproxy >/dev/null; then
            echo "ℹ️ Wireproxy sudah berjalan di latar belakang."
            exit 0
        fi

        # List file konfigurasi VPN yang tersedia (dibuat secara dinamis oleh Nix dari secrets/vpn-files)
        configs=(${vpnPaths})

        if [ ''${#configs[@]} -eq 0 ]; then
            echo "❌ Error: Tidak ada berkas konfigurasi VPN yang terdaftar."
            exit 1
        fi

        # Jika hanya ada satu konfigurasi, langsung gunakan tanpa bertanya
        secret_conf=""
        if [ ''${#configs[@]} -eq 1 ]; then
            secret_conf="''${configs[0]}"
        else
            echo "======= Pilihan Koneksi VPN ======="
            for i in "''${!configs[@]}"; do
                name=$(basename "''${configs[$i]}" .conf)
                echo " [$((i+1))] $name"
            done
            echo "==================================="

            read -r -p "Pilih nomor (default 1): " choice
            if [ -z "$choice" ]; then
                choice=1
            fi

            if [[ ! "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ''${#configs[@]} ]; then
                echo "❌ Error: Pilihan tidak valid."
                exit 1
            fi
            secret_conf="''${configs[$((choice-1))]}"
        fi

        # 1. Validasi keberadaan file rahasia
        if [ ! -f "$secret_conf" ]; then
            echo "❌ Error: File $secret_conf tidak ditemukan."
            exit 1
        fi

        # 2. Buat file sementara murni di dalam RAM (/dev/shm)
        temp_conf=$(mktemp /dev/shm/wp-conf.XXXXXX)

        # 3. Salin isi config asli (abaikan baris DNS asli)
        ${pkgs.gnugrep}/bin/grep -ivE '^[[:space:]]*dns[[:space:]]*=' "$secret_conf" > "$temp_conf"

        # Baca IP NextDNS kustom dari sops-nix (fallback ke IP standar publik jika tidak ada)
        dns_ip1=$(cat "${
          hmOpts.osConfig.sops.secrets."nextdns_ip1".path
        }" 2>/dev/null || echo "45.90.28.230")
        dns_ip2=$(cat "${
          hmOpts.osConfig.sops.secrets."nextdns_ip2".path
        }" 2>/dev/null || echo "45.90.30.230")

        # Injeksikan kustom NextDNS ke dalam bagian [Interface], SOCKS5 (1080), dan HTTP (1081) ke berkas konfigurasi sementara
        ${pkgs.gnused}/bin/sed -i '/\[Interface\]/a DNS = '"$dns_ip1, $dns_ip2" "$temp_conf"
        echo -e "\n[Socks5]\nBindAddress = 127.0.0.1:1080\n\n[HTTP]\nBindAddress = 127.0.0.1:1081" >> "$temp_conf"

        # 4. Eksekusi wireproxy di latar belakang, buang output debug yang berisik
        ${pkgs.wireproxy}/bin/wireproxy -c "$temp_conf" > /dev/null 2>&1 &
        WIREPROXY_PID=$!

        # Simpan PID dari proses wireproxy agar mudah dimatikan nanti
        mkdir -p ~/.cache/vpn
        echo "$WIREPROXY_PID" > ~/.cache/vpn/pid
        active_name=$(basename "$secret_conf" .conf)
        echo "$active_name" > ~/.cache/vpn/active_name

        # 5. Tunggu hingga wireproxy selesai membaca file konfigurasi dari RAM.
        # Polling /proc/$PID/fd lebih reliable dibanding sleep tetap:
        # cek apakah fd ke temp_conf sudah tidak ada (file telah di-close setelah dibaca).
        WAIT_ITER=0
        while [ $WAIT_ITER -lt 60 ]; do
            # Jika proses sudah tidak megang fd ke temp_conf, berarti sudah selesai baca
            if ! ${pkgs.coreutils}/bin/ls -la /proc/"$WIREPROXY_PID"/fd 2>/dev/null | ${pkgs.gnugrep}/bin/grep -qF "$temp_conf"; then
                break
            fi
            sleep 0.05
            WAIT_ITER=$((WAIT_ITER + 1))
        done

        # Hapus file konfigurasi dari RAM
        rm -f "$temp_conf"

        # Verifikasi apakah proses wireproxy benar-benar berjalan
        if ! kill -0 "$WIREPROXY_PID" 2>/dev/null; then
            echo "❌ Error: Wireproxy gagal berjalan (proses langsung keluar)."
            rm -f ~/.cache/vpn/pid ~/.cache/vpn/active_name
            exit 1
        fi

        echo "✅ Wireproxy aktif di latar belakang menggunakan $active_name (PID: $WIREPROXY_PID)."
        echo "✅ ALL_PROXY diarahkan ke 127.0.0.1:1080."
      '' [ ];

      vpn-switch-bin = selfLib.mkApp pkgs "vpn-switch-bin" ''
        # Hentikan wireproxy aktif jika sedang berjalan
        if ${pkgs.procps}/bin/pgrep -u "$(id -u)" -x wireproxy >/dev/null; then
            echo "🔄 Menghentikan VPN aktif..."
            ${vpn-off-bin} >/dev/null

            # Tunggu sebentar agar port dilepaskan
            sleep 0.5
        fi

        # Jalankan koneksi baru
        ${vpn-on-bin}
      '' [ ];

      socksProxyUrl = "socks5h://127.0.0.1:1080";
      httpProxyUrl = "http://127.0.0.1:1081";

      bashExportProxy = ''
        export ALL_PROXY="${socksProxyUrl}" all_proxy="${socksProxyUrl}"
        export http_proxy="${httpProxyUrl}" https_proxy="${httpProxyUrl}" HTTP_PROXY="${httpProxyUrl}" HTTPS_PROXY="${httpProxyUrl}"
      '';
      bashUnsetProxy = "unset ALL_PROXY all_proxy http_proxy https_proxy HTTP_PROXY HTTPS_PROXY";

      fishExportProxy = ''
        set -gx ALL_PROXY "${socksProxyUrl}"
        set -gx all_proxy "${socksProxyUrl}"
        set -gx http_proxy "${httpProxyUrl}"
        set -gx https_proxy "${httpProxyUrl}"
        set -gx HTTP_PROXY "${httpProxyUrl}"
        set -gx HTTPS_PROXY "${httpProxyUrl}"
      '';
      fishUnsetProxy = "set -e ALL_PROXY all_proxy http_proxy https_proxy HTTP_PROXY HTTPS_PROXY";

      commonVpn = ''
                vpn-on() {
                  ${vpn-on-bin}
                  if [ $? -eq 0 ]; then
        ${bashExportProxy}
                  fi
                }
                vpn-off() {
                  ${vpn-off-bin}
        ${bashUnsetProxy}
                }
                vpn-switch() {
                  ${vpn-switch-bin}
                  if [ $? -eq 0 ]; then
        ${bashExportProxy}
                  fi
                }
      '';
    in
    {
      home.packages = [
        vpn-off-bin
        vpn-on-bin
        vpn-switch-bin
      ];

      # Integrasi fungsi shell agar kompatibel dan dapat menset ALL_PROXY di sesi induk
      programs.fish.functions = {
        vpn-on = {
          description = "Jalankan Wireproxy via RAM dan aktifkan SOCKS5";
          body = ''
                        ${vpn-on-bin}
                        if test $status -eq 0
            ${fishExportProxy}
                        end
          '';
        };
        vpn-off = {
          description = "Hentikan Wireproxy dan hapus variabel proxy";
          body = ''
                        ${vpn-off-bin}
            ${fishUnsetProxy}
          '';
        };
        vpn-switch = {
          description = "Ganti koneksi VPN aktif ke konfigurasi lain";
          body = ''
                        ${vpn-switch-bin}
                        if test $status -eq 0
            ${fishExportProxy}
                        end
          '';
        };
      };

      programs.bash.initExtra = commonVpn;
      programs.zsh.initExtra = commonVpn;
    };
}
