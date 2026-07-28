{
  config,
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "services.networking.vpn";
  description = "WireGuard VPN and Wireproxy SOCKS5 local tunnel service";

  nixosConfig = {
    sops.secrets = {
      "wg-lan.conf" = {
        format = "binary";
        sopsFile = selfLib.secretBinary "vpn/wg-lan.enc.conf";
        owner = config.my.user.name;
        mode = "0400";
      };
      "wg-wifi.conf" = {
        format = "binary";
        sopsFile = selfLib.secretBinary "vpn/wg-wifi.enc.conf";
        owner = config.my.user.name;
        mode = "0400";
      };
      "wgcf-account.conf" = {
        format = "binary";
        sopsFile = selfLib.secretBinary "vpn/wgcf-account.enc";
        owner = config.my.user.name;
        mode = "0400";
      };
      "nextdns_ip1" = {
        owner = config.my.user.name;
        mode = "0400";
      };
      "nextdns_ip2" = {
        owner = config.my.user.name;
        mode = "0400";
      };
    };
  };

  hmConfig =
    hmOpts:
    let
      vpn-off-bin = pkgs.writeShellScriptBin "vpn-off-bin" ''
        if ${pkgs.procps}/bin/pgrep -u "$(id -u)" -x wireproxy >/dev/null; then
            ${pkgs.procps}/bin/pkill -u "$(id -u)" -x wireproxy 2>/dev/null || true
            sleep 0.5
        fi
        rm -f ~/.cache/vpn/pid ~/.cache/vpn/active_name
        echo "✅ Wireproxy dihentikan dan SOCKS5 proxy dilepas."
      '';

      vpn-on-bin = pkgs.writeShellScriptBin "vpn-on-bin" ''
        _vpn_pre_ip=$(ALL_PROXY= ${pkgs.curl}/bin/curl -s --max-time 3 https://ifconfig.me || echo "unknown")
        _vpn_pre_asn=$(ALL_PROXY= ${pkgs.curl}/bin/curl -s --max-time 3 https://ipinfo.io/org || echo "unknown")
        if [ "$_vpn_pre_asn" != "unknown" ]; then
            _vpn_pre_asn=$(echo "$_vpn_pre_asn" | cut -d' ' -f 1)
        fi

        if ${pkgs.procps}/bin/pgrep -u "$(id -u)" -x wireproxy >/dev/null; then
            active_name=$(cat ~/.cache/vpn/active_name 2>/dev/null || echo "Unknown")
            echo "⚠️ Wireproxy sudah berjalan (aktif: $active_name)."
            echo "💡 Gunakan 'vpn-switch' untuk mengganti koneksi atau 'vpn-off' untuk mematikan."
            exit 0
        fi

        sops_dir="/run/secrets"
        vpn_port="1080"

        options=()
        conf_files=()

        if [ -f "$sops_dir/wg-lan.conf" ]; then
            options+=("WireGuard (LAN)")
            conf_files+=("$sops_dir/wg-lan.conf")
        fi

        if [ -f "$sops_dir/wg-wifi.conf" ]; then
            options+=("WireGuard (WiFi)")
            conf_files+=("$sops_dir/wg-wifi.conf")
        fi

        if [ -f "$sops_dir/wgcf-account.conf" ]; then
            options+=("WGCF (Cloudflare WARP)")
            conf_files+=("$sops_dir/wgcf-account.conf")
        fi

        if [ ''${#options[@]} -eq 0 ]; then
            echo "❌ Error: Tidak ada berkas konfigurasi VPN yang ditemukan di $sops_dir."
            exit 1
        fi

        echo "🔒 Pilih profil VPN yang ingin diaktifkan:"
        selected_index=""

        if [ ''${#options[@]} -eq 1 ]; then
            echo "1) ''${options[0]} (Satu-satunya profil yang tersedia)"
            selected_index=0
        else
            for i in "''${!options[@]}"; do
                echo "$((i+1))) ''${options[$i]}"
            done

            read -rp "Masukkan pilihan (1-''${#options[@]}): " choice
            if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ''${#options[@]} ]; then
                selected_index=$((choice-1))
            else
                echo "❌ Pilihan tidak valid."
                exit 1
            fi
        fi

        secret_conf="''${conf_files[$selected_index]}"

        temp_conf=$(mktemp /tmp/wireproxy.XXXXXX.conf)
        chmod 600 "$temp_conf"
        trap 'rm -f "$temp_conf"' EXIT

        ${pkgs.gnugrep}/bin/grep -ivE '^[[:space:]]*dns[[:space:]]*=' "$secret_conf" > "$temp_conf"

        dns_ip1=$(cat "${
          hmOpts.osConfig.sops.secrets."nextdns_ip1".path
        }" 2>/dev/null || echo "45.90.28.230")
        dns_ip2=$(cat "${
          hmOpts.osConfig.sops.secrets."nextdns_ip2".path
        }" 2>/dev/null || echo "45.90.30.230")

        ${pkgs.gnused}/bin/sed -i '/\[Interface\]/a DNS = '"$dns_ip1, $dns_ip2" "$temp_conf"
        echo -e "\n[Socks5]\nBindAddress = 127.0.0.1:$vpn_port" >> "$temp_conf"

        ${pkgs.wireproxy}/bin/wireproxy -c "$temp_conf" > /dev/null 2>&1 &
        WIREPROXY_PID=$!

        mkdir -p ~/.cache/vpn
        echo "$WIREPROXY_PID" > ~/.cache/vpn/pid
        active_name=$(basename "$secret_conf" .conf)
        echo "$active_name" > ~/.cache/vpn/active_name

        sleep 0.5

        if ! kill -0 "$WIREPROXY_PID" 2>/dev/null; then
            echo "❌ Error: Wireproxy gagal berjalan (proses langsung keluar)."
            rm -f ~/.cache/vpn/pid ~/.cache/vpn/active_name
            exit 1
        fi

        echo "✅ Wireproxy aktif di latar belakang menggunakan $active_name (PID: $WIREPROXY_PID)."
        echo "✅ ALL_PROXY diarahkan ke 127.0.0.1:1080."

        exec vpn-verify-bin "$_vpn_pre_ip" "$_vpn_pre_asn"
      '';

      vpn-verify-bin = pkgs.writeShellScriptBin "vpn-verify-bin" ''
        pre_ip="$1"
        pre_asn="$2"

        echo "🔍 Memverifikasi keamanan koneksi (paranoid mode)..."
        sleep 2

        post_ip=""
        for attempt in {1..3}; do
            post_ip=$(ALL_PROXY=socks5h://127.0.0.1:1080 ${pkgs.curl}/bin/curl -s --max-time 3 https://ifconfig.me)
            if [ -n "$post_ip" ]; then
                break
            fi
            sleep 1
        done

        if [ -z "$post_ip" ]; then
            echo "❌ Error: Gagal terhubung ke internet via VPN proxy (RTO)."
            vpn-off-bin
            exit 1
        fi

        if [ "$pre_ip" != "unknown" ] && [ "$post_ip" = "$pre_ip" ]; then
            echo "❌ KEBOCORAN IP TERDETEKSI!"
            echo "   IP Anda ($post_ip) masih sama dengan IP ISP asli Anda."
            echo "   Menutup koneksi demi keamanan..."
            vpn-off-bin
            exit 1
        fi

        echo "✅ Keamanan terverifikasi: IP dialihkan ke $post_ip."
      '';

      vpn-switch-bin = pkgs.writeShellScriptBin "vpn-switch-bin" ''
        _vpn_pre_ip=$(ALL_PROXY= ${pkgs.curl}/bin/curl -s --max-time 3 https://ifconfig.me || echo "unknown")
        _vpn_pre_asn=$(ALL_PROXY= ${pkgs.curl}/bin/curl -s --max-time 3 https://ipinfo.io/org || echo "unknown")
        if [ "$_vpn_pre_asn" != "unknown" ]; then
            _vpn_pre_asn=$(echo "$_vpn_pre_asn" | cut -d' ' -f 1)
        fi

        if ${pkgs.procps}/bin/pgrep -u "$(id -u)" -x wireproxy >/dev/null; then
            echo "🔄 Menghentikan VPN aktif..."
            vpn-off-bin >/dev/null
            sleep 0.5
        fi

        vpn-on-bin
      '';

      commonVpn = ''
        vpn-on() {
          vpn-on-bin
          if [ $? -eq 0 ]; then
            export ALL_PROXY="socks5h://127.0.0.1:1080"
          fi
        }
        vpn-off() {
          vpn-off-bin
          unset ALL_PROXY
        }
        vpn-switch() {
          vpn-switch-bin
          if [ $? -eq 0 ]; then
            export ALL_PROXY="socks5h://127.0.0.1:1080"
          fi
        }
      '';
    in
    {
      home.packages = [
        vpn-off-bin
        vpn-on-bin
        vpn-verify-bin
        vpn-switch-bin
      ];

      programs.fish.functions = {
        vpn-on = {
          description = "Jalankan Wireproxy via RAM dan aktifkan SOCKS5";
          body = ''
            vpn-on-bin
            if test $status -eq 0
                set -gx ALL_PROXY "socks5h://127.0.0.1:1080"
            end
          '';
        };
        vpn-off = {
          description = "Hentikan Wireproxy dan hapus variabel proxy";
          body = ''
            vpn-off-bin
            set -e ALL_PROXY
          '';
        };
        vpn-switch = {
          description = "Ganti koneksi VPN aktif ke konfigurasi lain";
          body = ''
            vpn-switch-bin
            if test $status -eq 0
                set -gx ALL_PROXY "socks5h://127.0.0.1:1080"
            end
          '';
        };
      };

      programs.bash.initExtra = commonVpn;
      programs.zsh.initExtra = commonVpn;
    };
}
