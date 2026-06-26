{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "scripts.vpn";
  description = "VPN control scripts (wireproxy)";

  hmConfig = hmOpts: {
    programs.fish.functions = {
      vpn_on = {
        description = "Jalankan Wireproxy via RAM dan aktifkan SOCKS5";
        body = ''
          # 0. Cek apakah wireproxy sudah berjalan di sistem
          if ${pkgs.procps}/bin/pgrep -x wireproxy >/dev/null
              set -gx ALL_PROXY "socks5h://127.0.0.1:1080"
              echo "ℹ️ Wireproxy sudah berjalan di latar belakang."
              echo "✅ ALL_PROXY diarahkan ke 127.0.0.1:1080."
              set -l my_ip (${pkgs.curl}/bin/curl -s --max-time 5 ifconfig.me; or echo "Gagal mendapatkan IP")
              echo "🌐 IP Terminal Anda: $my_ip"
              return 0
          end

          set secret_conf "/run/secrets/proton-wg-sg19.conf"

          # 1. Validasi keberadaan file rahasia
          if not test -f $secret_conf
              echo "❌ Error: File $secret_conf tidak ditemukan."
              return 1
          end

          # 2. Buat file sementara murni di dalam RAM (/dev/shm)
          set temp_conf (mktemp /dev/shm/wp-conf.XXXXXX)

          # 3. Salin isi config asli dan injeksikan pengaturan SOCKS5
          cat $secret_conf > $temp_conf
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

          echo "✅ Wireproxy aktif di latar belakang (PID: $WIREPROXY_PID)."
          echo "✅ ALL_PROXY diarahkan ke 127.0.0.1:1080."
          
          # Beri waktu 2 detik agar handshake WireGuard selesai sebelum cek IP
          sleep 2
          set -l my_ip (${pkgs.curl}/bin/curl -s --max-time 5 ifconfig.me; or echo "Gagal mendapatkan IP")
          echo "🌐 IP Terminal Anda: $my_ip"
        '';
      };

      vpn_off = {
        description = "Hentikan Wireproxy dan hapus variabel proxy";
        body = ''
          # Matikan spesifik proses yang kita jalankan, atau semuanya jika tidak ditemukan
          if set -q WIREPROXY_PID
              kill $WIREPROXY_PID 2>/dev/null
              set -e WIREPROXY_PID
          else
              ${pkgs.psmisc}/bin/killall wireproxy 2>/dev/null
          end

          # Bersihkan variabel environment
          set -e ALL_PROXY
          
          echo "❌ Wireproxy dimatikan. Terminal kembali ke IP asli."
        '';
      };
    };
  };
}
