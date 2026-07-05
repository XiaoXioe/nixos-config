{
  pkgs,
  selfLib,
  ...
}:
let
  vpnDir = ../../secrets/vpn-files;
  vpnFiles = builtins.attrNames (builtins.readDir vpnDir);
  protonVpnFiles = builtins.filter (x: x != "wg-warp.conf") vpnFiles;
  vpnPaths = pkgs.lib.concatMapStringsSep " " (f: "\"/run/secrets/${f}\"") protonVpnFiles;

  vpn-off-bin = pkgs.writeShellScriptBin "vpn-off-bin" ''
    if [ -f ~/.cache/vpn/pid ]; then
        WIREPROXY_PID=$(cat ~/.cache/vpn/pid)
        kill "$WIREPROXY_PID" 2>/dev/null
        rm -f ~/.cache/vpn/pid ~/.cache/vpn/active_name
    else
        ${pkgs.procps}/bin/pkill -u "$(id -u)" -x wireproxy 2>/dev/null
    fi
    echo "❌ Wireproxy dimatikan. Terminal kembali ke IP asli."
  '';

  vpn-on-bin = pkgs.writeShellScriptBin "vpn-on-bin" ''
    # Ambil IP dan ASN asli sebelum VPN (bypassing any active proxy)
    _vpn_pre_ip=$(ALL_PROXY= ${pkgs.curl}/bin/curl -s --max-time 3 https://ifconfig.me || echo "unknown")
    _vpn_pre_asn=$(ALL_PROXY= ${pkgs.curl}/bin/curl -s --max-time 3 https://ipinfo.io/org || echo "unknown")
    if [ "$_vpn_pre_asn" != "unknown" ]; then
        _vpn_pre_asn=$(echo "$_vpn_pre_asn" | cut -d' ' -f 1)
    fi

    # Cek apakah wireproxy milik user ini sudah berjalan
    if ${pkgs.procps}/bin/pgrep -u "$(id -u)" -x wireproxy >/dev/null; then
        echo "ℹ️ Wireproxy sudah berjalan di latar belakang."
        # Run verification directly
        exec vpn-verify-bin "$_vpn_pre_ip" "$_vpn_pre_asn"
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
    dns_ip1=$(cat /run/secrets/nextdns_ip1 2>/dev/null || echo "45.90.28.230")
    dns_ip2=$(cat /run/secrets/nextdns_ip2 2>/dev/null || echo "45.90.30.230")

    # Injeksikan kustom NextDNS ke dalam bagian [Interface] dan SOCKS5 ke berkas konfigurasi sementara
    ${pkgs.gnused}/bin/sed -i '/\[Interface\]/a DNS = '"$dns_ip1, $dns_ip2" "$temp_conf"
    echo -e "\n[Socks5]\nBindAddress = 127.0.0.1:1080" >> "$temp_conf"

    # 4. Eksekusi wireproxy di latar belakang, buang output debug yang berisik
    ${pkgs.wireproxy}/bin/wireproxy -c "$temp_conf" > /dev/null 2>&1 &
    WIREPROXY_PID=$!

    # Simpan PID dari proses wireproxy agar mudah dimatikan nanti
    mkdir -p ~/.cache/vpn
    echo "$WIREPROXY_PID" > ~/.cache/vpn/pid
    active_name=$(basename "$secret_conf" .conf)
    echo "$active_name" > ~/.cache/vpn/active_name

    # Beri waktu sebentar agar wireproxy selesai membaca berkas konfigurasi sebelum dihapus
    sleep 0.5

    # 5. Segera hapus file konfigurasi dari RAM setelah dibaca sistem
    rm -f "$temp_conf"

    # Verifikasi apakah proses wireproxy benar-benar berjalan
    if ! kill -0 "$WIREPROXY_PID" 2>/dev/null; then
        echo "❌ Error: Wireproxy gagal berjalan (proses langsung keluar)."
        rm -f ~/.cache/vpn/pid ~/.cache/vpn/active_name
        exit 1
    fi

    echo "✅ Wireproxy aktif di latar belakang menggunakan $active_name (PID: $WIREPROXY_PID)."
    echo "✅ ALL_PROXY diarahkan ke 127.0.0.1:1080."

    # Verifikasi keamanan koneksi (paranoid mode)
    exec vpn-verify-bin "$_vpn_pre_ip" "$_vpn_pre_asn"
  '';

  vpn-verify-bin = pkgs.writeShellScriptBin "vpn-verify-bin" ''
    pre_ip="$1"
    pre_asn="$2"

    echo "🔍 Memverifikasi keamanan koneksi (paranoid mode)..."
    sleep 2

    # 1. Cek IP pasca-VPN
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

    # 2. Uji Kebocoran DNS (DNS Leak Test)
    echo "🔍 Menjalankan uji kebocoran DNS..."
    id=$(ALL_PROXY=socks5h://127.0.0.1:1080 ${pkgs.curl}/bin/curl -s --max-time 3 https://bash.ws/id)
    if [ -z "$id" ]; then
        echo "⚠️ Peringatan: Gagal memicu DNS leak test (API offline)."
        echo "🌐 IP Terminal Baru Anda: $post_ip"
        exit 0
    fi

    # Trigger DNS queries in background to force resolution through SOCKS5 proxy
    for i in {1..5}; do
        ALL_PROXY=socks5h://127.0.0.1:1080 ${pkgs.curl}/bin/curl -s "https://$i.$id.bash.ws" >/dev/null 2>&1 &
    done
    sleep 1.5

    # Ambil hasil uji (harus lewat proxy agar client IP terdeteksi sebagai IP VPN)
    dns_result=$(ALL_PROXY=socks5h://127.0.0.1:1080 ${pkgs.curl}/bin/curl -s --max-time 3 "https://bash.ws/dnsleak/test/$id?json")
    conclusion=$(echo "$dns_result" | ${pkgs.jq}/bin/jq -r '.[] | select(.type == "conclusion") | .ip' 2>/dev/null)
    dns_servers=$(echo "$dns_result" | ${pkgs.jq}/bin/jq -r '.[] | select(.type == "dns") | "\(.ip) [\(.country_name) - \(.asn)]"' 2>/dev/null)

    if [ -n "$dns_servers" ]; then
        echo "🌐 DNS Resolver yang terdeteksi:"
        while read -r server; do
            echo "   -> $server"
        done <<< "$dns_servers"
    fi

    # Analisis kebocoran secara cerdas: cek apakah ada resolver DNS yang memiliki ASN sama dengan ISP fisik asli Anda
    real_leak="no"
    dns_asns=$(echo "$dns_result" | ${pkgs.jq}/bin/jq -r '.[] | select(.type == "dns") | .asn' 2>/dev/null)
    if [ -n "$dns_asns" ]; then
        while read -r dns_asn; do
            clean_asn=$(echo "$dns_asn" | cut -d' ' -f 1)
            if [ "$pre_asn" != "unknown" ] && [ "$clean_asn" = "$pre_asn" ]; then
                real_leak="yes"
                break
            fi
        done <<< "$dns_asns"
    fi

    if [ "$real_leak" = "yes" ]; then
        echo "❌ KEBOCORAN DNS NYATA TERDETEKSI! ($conclusion)"
        echo "   Permintaan DNS Anda bocor ke resolver ISP fisik asli Anda ($pre_asn)."
        echo "   Menutup koneksi demi keamanan..."
        vpn-off-bin
        exit 1
    fi

    echo "✅ Keamanan terverifikasi: IP dialihkan ke $post_ip."
    if [[ "$conclusion" =~ leak ]]; then
        echo "ℹ️ Catatan: Uji publik melaporkan ketidakcocokan ASN (karena Anda menggunakan NextDNS kustom, bukan DNS bawaan VPN),"
        echo "    tetapi kueri terverifikasi aman karena tidak membocorkan data ke ISP asli Anda ($pre_asn)."
    else
        echo "✅ Aman: Tidak ada kebocoran DNS terdeteksi."
    fi
  '';

  vpn-switch-bin = pkgs.writeShellScriptBin "vpn-switch-bin" ''
    # Ambil IP dan ASN asli sebelum VPN (bypassing any active proxy)
    _vpn_pre_ip=$(ALL_PROXY= ${pkgs.curl}/bin/curl -s --max-time 3 https://ifconfig.me || echo "unknown")
    _vpn_pre_asn=$(ALL_PROXY= ${pkgs.curl}/bin/curl -s --max-time 3 https://ipinfo.io/org || echo "unknown")
    if [ "$_vpn_pre_asn" != "unknown" ]; then
        _vpn_pre_asn=$(echo "$_vpn_pre_asn" | cut -d' ' -f 1)
    fi

    # Hentikan wireproxy aktif jika sedang berjalan
    if ${pkgs.procps}/bin/pgrep -u "$(id -u)" -x wireproxy >/dev/null; then
        echo "🔄 Menghentikan VPN aktif..."
        vpn-off-bin >/dev/null
        # Tunggu sebentar agar port dilepaskan
        sleep 0.5
    fi

    # Jalankan koneksi baru
    vpn-on-bin
  '';
in
selfLib.mkModule {
  name = "scripts.vpn";
  description = "VPN control scripts (wireproxy)";

  hmConfig = hmOpts: {
    home.packages = [
      vpn-off-bin
      vpn-on-bin
      vpn-verify-bin
      vpn-switch-bin
    ];

    # Integrasi fungsi shell agar kompatibel dan dapat menset ALL_PROXY di sesi induk
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

    programs.bash.initExtra = ''
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

    programs.zsh.initExtra = ''
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
  };
}
