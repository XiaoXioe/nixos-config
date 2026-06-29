{
  pkgs,
  selfLib,
  ...
}:

let
  vpnDir = ../../secrets/vpn-files;
  vpnFiles = selfLib.getVpnFiles vpnDir;
  protonVpnFiles = builtins.filter (x: x != "wg-warp.conf") vpnFiles;
  vpnPaths = pkgs.lib.concatMapStringsSep " " (f: "\"/run/secrets/${f}\"") protonVpnFiles;
in
selfLib.mkModule {
  name = "scripts.vpn";
  description = "VPN control scripts (wireproxy)";

  hmConfig = hmOpts: {
    programs.fish.functions = {
      vpn-on = {
        description = "Jalankan Wireproxy via RAM dan aktifkan SOCKS5";
        body = ''
          # Ambil IP dan ASN asli sebelum VPN (bypassing any active proxy)
          set -l pre_ip (env ALL_PROXY= ${pkgs.curl}/bin/curl -s --max-time 3 https://ifconfig.me; or echo "unknown")
          set -l pre_asn (env ALL_PROXY= ${pkgs.curl}/bin/curl -s --max-time 3 https://ipinfo.io/org; or echo "unknown")
          if test "$pre_asn" != "unknown"
              set pre_asn (echo $pre_asn | cut -d' ' -f 1)
          end

          # 0. Cek apakah wireproxy milik user ini sudah berjalan
          if ${pkgs.procps}/bin/pgrep -u (id -u) -x wireproxy >/dev/null
              set -gx ALL_PROXY "socks5h://127.0.0.1:1080"
              echo "ℹ️ Wireproxy sudah berjalan di latar belakang."
              echo "✅ ALL_PROXY diarahkan ke 127.0.0.1:1080."
              if not _vpn-verify $pre_ip $pre_asn
                  return 1
              end
              return 0
          end

          # List file konfigurasi VPN yang tersedia (dibuat secara dinamis oleh Nix)
          set -l configs ${vpnPaths}

          if test (count $configs) -eq 0
              echo "❌ Error: Tidak ada berkas konfigurasi VPN yang terdaftar."
              return 1
          end

          # Jika hanya ada satu konfigurasi, langsung gunakan tanpa bertanya
          set -l secret_conf ""
          if test (count $configs) -eq 1
              set secret_conf $configs[1]
          else
              echo "======= Pilihan Koneksi VPN ======="
              for i in (seq (count $configs))
                  set -l name (basename $configs[$i] .conf)
                  echo " [$i] $name"
              end
              echo "==================================="

              read -l choice -p 'echo -n "Pilih nomor (default 1): "'
              if test -z "$choice"
                  set choice 1
              end

              if not string match -qr '^[0-9]+$' $choice; or test $choice -lt 1; or test $choice -gt (count $configs)
                  echo "❌ Error: Pilihan tidak valid."
                  return 1
              end
              set secret_conf $configs[$choice]
          end

          # 1. Validasi keberadaan file rahasia
          if not test -f $secret_conf
              echo "❌ Error: File $secret_conf tidak ditemukan."
              return 1
          end

          # 2. Buat file sementara murni di dalam RAM (/dev/shm)
          set temp_conf (mktemp /dev/shm/wp-conf.XXXXXX)

          # 3. Salin isi config asli (abaikan baris DNS asli)
          ${pkgs.gnugrep}/bin/grep -ivE '^[[:space:]]*dns[[:space:]]*=' $secret_conf > $temp_conf

          # Baca IP NextDNS kustom dari sops-nix (fallback ke IP standar publik jika tidak ada)
          set -l dns_ip1 (cat /run/secrets/nextdns_ip1 2>/dev/null; or echo "45.90.28.230")
          set -l dns_ip2 (cat /run/secrets/nextdns_ip2 2>/dev/null; or echo "45.90.30.230")

          # Injeksikan kustom NextDNS ke dalam bagian [Interface] dan SOCKS5 ke berkas konfigurasi sementara
          ${pkgs.gnused}/bin/sed -i '/\[Interface\]/a DNS = '"$dns_ip1, $dns_ip2" $temp_conf
          echo -e "\n[Socks5]\nBindAddress = 127.0.0.1:1080" >> $temp_conf

          # 4. Eksekusi wireproxy di latar belakang, buang output debug yang berisik
          ${pkgs.wireproxy}/bin/wireproxy -c $temp_conf > /dev/null 2>&1 &
          
          # Simpan PID dari proses wireproxy agar mudah dimatikan nanti
          set -gx WIREPROXY_PID $last_pid

          # Beri waktu sebentar agar wireproxy selesai membaca berkas konfigurasi sebelum dihapus
          sleep 0.5

          # 5. Segera hapus file konfigurasi dari RAM setelah dibaca sistem
          rm -f $temp_conf

          # Verifikasi apakah proses wireproxy benar-benar berjalan
          if not kill -0 $WIREPROXY_PID 2>/dev/null
              echo "❌ Error: Wireproxy gagal berjalan (proses langsung keluar)."
              set -e WIREPROXY_PID
              return 1
          end

          # 6. Terapkan proxy ke sesi terminal saat ini
          set -gx ALL_PROXY "socks5h://127.0.0.1:1080"

          set -l vpn_active_name (basename $secret_conf .conf)
          echo "✅ Wireproxy aktif di latar belakang menggunakan $vpn_active_name (PID: $WIREPROXY_PID)."
          echo "✅ ALL_PROXY diarahkan ke 127.0.0.1:1080."
          
          # Beri waktu 2 detik agar handshake WireGuard selesai sebelum cek IP
          sleep 2
          
          # Verifikasi keamanan koneksi (paranoid mode)
          if not _vpn-verify $pre_ip $pre_asn
              return 1
          end
        '';
      };

      vpn-off = {
        description = "Hentikan Wireproxy dan hapus variabel proxy";
        body = ''
          # Matikan spesifik proses yang kita jalankan, atau semuanya milik user ini jika tidak ditemukan
          if set -q WIREPROXY_PID
              kill $WIREPROXY_PID 2>/dev/null
              set -e WIREPROXY_PID
          else
              ${pkgs.procps}/bin/pkill -u (id -u) -x wireproxy 2>/dev/null
          end

          # Bersihkan variabel environment
          set -e ALL_PROXY
          
          echo "❌ Wireproxy dimatikan. Terminal kembali ke IP asli."
        '';
      };

      vpn-switch = {
        description = "Ganti koneksi VPN aktif ke konfigurasi lain";
        body = ''
          # Ambil IP dan ASN asli sebelum VPN (bypassing any active proxy)
          set -l pre_ip (env ALL_PROXY= ${pkgs.curl}/bin/curl -s --max-time 3 https://ifconfig.me; or echo "unknown")
          set -l pre_asn (env ALL_PROXY= ${pkgs.curl}/bin/curl -s --max-time 3 https://ipinfo.io/org; or echo "unknown")
          if test "$pre_asn" != "unknown"
              set pre_asn (echo $pre_asn | cut -d' ' -f 1)
          end

          # 1. Hentikan wireproxy aktif jika sedang berjalan
          if ${pkgs.procps}/bin/pgrep -u (id -u) -x wireproxy >/dev/null
              echo "🔄 Menghentikan VPN aktif..."
              if set -q WIREPROXY_PID
                  kill $WIREPROXY_PID 2>/dev/null
                  set -e WIREPROXY_PID
              else
                  ${pkgs.procps}/bin/pkill -u (id -u) -x wireproxy 2>/dev/null
              end
              # Tunggu sebentar agar port dilepaskan
              sleep 0.5
          end

          # List file konfigurasi VPN yang tersedia (dibuat secara dinamis oleh Nix)
          set -l configs ${vpnPaths}

          if test (count $configs) -eq 0
              echo "❌ Error: Tidak ada berkas konfigurasi VPN yang terdaftar."
              set -e ALL_PROXY
              return 1
          end

          # Pilihan menu jika terdapat lebih dari 1 VPN
          set -l secret_conf ""
          if test (count $configs) -eq 1
              set secret_conf $configs[1]
          else
              echo "======= Pilihan Koneksi VPN ======="
              for i in (seq (count $configs))
                  set -l name (basename $configs[$i] .conf)
                  echo " [$i] $name"
              end
              echo "==================================="

              read -l choice -p 'echo -n "Pilih nomor (default 1): "'
              if test -z "$choice"
                  set choice 1
              end

              if not string match -qr '^[0-9]+$' $choice; or test $choice -lt 1; or test $choice -gt (count $configs)
                  echo "❌ Error: Pilihan tidak valid."
                  return 1
              end
              set secret_conf $configs[$choice]
          end

          # 2. Validasi keberadaan file rahasia
          if not test -f $secret_conf
              echo "❌ Error: File $secret_conf tidak ditemukan."
              set -e ALL_PROXY
              return 1
          end

          # 3. Buat file sementara murni di dalam RAM (/dev/shm)
          set temp_conf (mktemp /dev/shm/wp-conf.XXXXXX)

          # 4. Salin isi config asli (abaikan baris DNS asli)
          ${pkgs.gnugrep}/bin/grep -ivE '^[[:space:]]*dns[[:space:]]*=' $secret_conf > $temp_conf

          # Baca IP NextDNS kustom dari sops-nix (fallback ke IP standar publik jika tidak ada)
          set -l dns_ip1 (cat /run/secrets/nextdns_ip1 2>/dev/null; or echo "45.90.28.230")
          set -l dns_ip2 (cat /run/secrets/nextdns_ip2 2>/dev/null; or echo "45.90.30.230")

          # Injeksikan kustom NextDNS ke dalam bagian [Interface] dan SOCKS5 ke berkas konfigurasi sementara
          ${pkgs.gnused}/bin/sed -i '/\[Interface\]/a DNS = '"$dns_ip1, $dns_ip2" $temp_conf
          echo -e "\n[Socks5]\nBindAddress = 127.0.0.1:1080" >> $temp_conf

          # 5. Eksekusi wireproxy di latar belakang, buang output debug yang berisik
          ${pkgs.wireproxy}/bin/wireproxy -c $temp_conf > /dev/null 2>&1 &
          
          # Simpan PID dari proses wireproxy agar mudah dimatikan nanti
          set -gx WIREPROXY_PID $last_pid

          # Beri waktu sebentar agar wireproxy selesai membaca berkas konfigurasi sebelum dihapus
          sleep 0.5

          # 6. Segera hapus file konfigurasi dari RAM setelah dibaca sistem
          rm -f $temp_conf

          # Verifikasi apakah proses wireproxy benar-benar berjalan
          if not kill -0 $WIREPROXY_PID 2>/dev/null
              echo "❌ Error: Wireproxy gagal berjalan (proses langsung keluar)."
              set -e WIREPROXY_PID
              set -e ALL_PROXY
              return 1
          end

          # 7. Terapkan proxy ke sesi terminal saat ini
          set -gx ALL_PROXY "socks5h://127.0.0.1:1080"

          set -l vpn_active_name (basename $secret_conf .conf)
          echo "🔄 Berhasil beralih ke $vpn_active_name (PID: $WIREPROXY_PID)."
          echo "✅ ALL_PROXY diarahkan ke 127.0.0.1:1080."
          
          # Beri waktu 2 detik agar handshake WireGuard selesai sebelum cek IP
          sleep 2
          
          # Verifikasi keamanan koneksi (paranoid mode)
          if not _vpn-verify $pre_ip $pre_asn
              return 1
          end
        '';
      };

      _vpn-verify = {
        description = "Verifikasi keamanan koneksi VPN (IP leak & DNS leak check)";
        body = ''
          set -l pre_ip $argv[1]
          set -l pre_asn $argv[2]
          
          echo "🔍 Memverifikasi keamanan koneksi (paranoid mode)..."
          
          # 1. Cek IP pasca-VPN
          set -l post_ip ""
          for attempt in (seq 1 3)
              set post_ip (${pkgs.curl}/bin/curl -s --max-time 3 https://ifconfig.me)
              if test -n "$post_ip"
                  break
              end
              sleep 1
          end

          if test -z "$post_ip"
              echo "❌ Error: Gagal terhubung ke internet via VPN proxy (RTO)."
              vpn-off
              return 1
          end

          if test "$pre_ip" != "unknown" -a "$post_ip" = "$pre_ip"
              echo "❌ KEBOCORAN IP TERDETEKSI!"
              echo "   IP Anda ($post_ip) masih sama dengan IP ISP asli Anda."
              echo "   Menutup koneksi demi keamanan..."
              vpn-off
              return 1
          end

          # 2. Uji Kebocoran DNS (DNS Leak Test)
          echo "🔍 Menjalankan uji kebocoran DNS..."
          set -l id (${pkgs.curl}/bin/curl -s --max-time 3 https://bash.ws/id)
          if test -z "$id"
              echo "⚠️ Peringatan: Gagal memicu DNS leak test (API offline)."
              echo "🌐 IP Terminal Baru Anda: $post_ip"
              return 0
          end

          # Trigger DNS queries in background to force resolution through SOCKS5 proxy
          for i in (seq 1 5)
              ${pkgs.curl}/bin/curl -s "https://$i.$id.bash.ws" >/dev/null 2>&1 &
          end
          sleep 1.5

          # Ambil hasil uji (harus lewat proxy agar client IP terdeteksi sebagai IP VPN)
          set -l dns_result (${pkgs.curl}/bin/curl -s --max-time 3 "https://bash.ws/dnsleak/test/$id?json")
          set -l conclusion (echo $dns_result | ${pkgs.jq}/bin/jq -r '.[] | select(.type == "conclusion") | .ip' 2>/dev/null)
          set -l dns_servers (echo $dns_result | ${pkgs.jq}/bin/jq -r '.[] | select(.type == "dns") | "\(.ip) [\(.country_name) - \(.asn)]"' 2>/dev/null)

          if test -n "$dns_servers"
              echo "🌐 DNS Resolver yang terdeteksi:"
              for server in $dns_servers
                  echo "   -> $server"
              end
          end

          # Analisis kebocoran secara cerdas: cek apakah ada resolver DNS yang memiliki ASN sama dengan ISP fisik asli Anda
          set -l real_leak "no"
          for dns_asn in (echo $dns_result | ${pkgs.jq}/bin/jq -r '.[] | select(.type == "dns") | .asn' 2>/dev/null)
              set -l clean_asn (echo $dns_asn | cut -d' ' -f 1)
              if test "$pre_asn" != "unknown" -a "$clean_asn" = "$pre_asn"
                  set real_leak "yes"
                  break
              end
          end

          if test "$real_leak" = "yes"
              echo "❌ KEBOCORAN DNS NYATA TERDETEKSI! ($conclusion)"
              echo "   Permintaan DNS Anda bocor ke resolver ISP fisik asli Anda ($pre_asn)."
              echo "   Menutup koneksi demi keamanan..."
              vpn-off
              return 1
          end

          echo "✅ Keamanan terverifikasi: IP dialihkan ke $post_ip."
          if string match -qi "*leak*" "$conclusion"
              echo "ℹ️ Catatan: Uji publik melaporkan ketidakcocokan ASN (karena Anda menggunakan NextDNS kustom, bukan DNS bawaan VPN),"
              echo "    tetapi kueri terverifikasi aman karena tidak membocorkan data ke ISP asli Anda ($pre_asn)."
          else
              echo "✅ Aman: Tidak ada kebocoran DNS terdeteksi."
          end
        '';
      };
    };
  };
}
