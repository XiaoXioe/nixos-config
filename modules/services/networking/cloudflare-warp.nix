{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "services.networking.cloudflare-warp";
  description = "Cloudflare WARP service and automated setup";

  nixosConfig = {
    environment.systemPackages = [
      pkgs.cloudflare-warp
    ];

    services.cloudflare-warp.enable = true;

    systemd.services.cloudflare-warp-setup = {
      description = "Automate Cloudflare WARP Proxy Setup";
      wantedBy = [ "multi-user.target" ];
      after = [ "cloudflare-warp.service" ];
      requires = [ "cloudflare-warp.service" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script = ''
        # Tunggu hingga daemon warp-svc siap menerima koneksi (maksimal 30 detik)
        echo "Menunggu daemon warp-svc..."
        for i in {1..30}; do
          if ${pkgs.cloudflare-warp}/bin/warp-cli --accept-tos status >/dev/null 2>&1; then
            break
          fi
          sleep 1
        done

        # Cek status saat ini
        STATUS=$(${pkgs.cloudflare-warp}/bin/warp-cli --accept-tos status)

        # Jika belum terdaftar, jalankan rangkaian perintah proxy
        if echo "$STATUS" | grep -qi "Registration missing"; then
          echo "Registrasi WARP belum ditemukan. Memulai konfigurasi otomatis..."
          ${pkgs.cloudflare-warp}/bin/warp-cli --accept-tos registration new
          ${pkgs.cloudflare-warp}/bin/warp-cli --accept-tos mode proxy
          ${pkgs.cloudflare-warp}/bin/warp-cli --accept-tos proxy port 40000
          ${pkgs.cloudflare-warp}/bin/warp-cli --accept-tos connect
          echo "Konfigurasi WARP Proxy selesai!"
        else
          echo "WARP sudah terkonfigurasi. Melewati setup."
        fi
      '';
    };

    systemd.services.cloudflare-warp = {
      serviceConfig = {
        LogLevelMax = "err";
      };
    };
  };
}
