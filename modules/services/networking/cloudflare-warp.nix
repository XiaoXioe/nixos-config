{
  pkgs,
  selfLib,
  lib,
  ...
}:

selfLib.mkModule {
  name = "services.networking.cloudflare-warp";
  description = "Wireproxy based Cloudflare WARP service (In-Memory Generation)";

  options = {
    port = lib.mkOption {
      type = lib.types.port;
      default = 40000;
      description = "SOCKS5 proxy port for Cloudflare WARP";
    };
  };

  preservation = {
    persist = true;
    directories = [
      "/var/lib/cloudflare-warp"
      {
        directory = "/var/lib/private/wireproxy-warp";
        mode = "0700";
      }
    ];
  };

  nixosConfig =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      warpSetupScript =
        selfLib.mkApp pkgs "generate-warp-config"
          ''
            cd "$STATE_DIRECTORY"

            if [[ ! -f wgcf-profile.conf ]]; then
              echo "==> [wireproxy-warp] Berkas profil tidak ditemukan. Memulai pendaftaran akun baru..."
              rm -f wgcf-profile.conf.tmp wgcf-account.toml

              MAX_RETRIES=5
              RETRY_COUNT=0
              SUCCESS=0

              while [[ $RETRY_COUNT -lt $MAX_RETRIES ]]; do
                if [[ ! -f wgcf-account.toml ]]; then
                  wgcf register --accept-tos >/dev/null 2>&1 || true
                fi

                if wgcf generate >/dev/null 2>&1; then
                  SUCCESS=1
                  break
                fi

                RETRY_COUNT=$((RETRY_COUNT + 1))
                echo "==> [wireproxy-warp] Gagal mendaftar/generate profile. Percobaan $RETRY_COUNT dari $MAX_RETRIES..."
                sleep 3
              done

              if [[ $SUCCESS -ne 1 ]]; then
                echo "❌ [wireproxy-warp] Gagal melakukan pendaftaran WGCF setelah $MAX_RETRIES percobaan."
                exit 1
              fi

              # Tambahkan konfigurasi SOCKS5 secara atomik
              {
                echo ""
                echo "[Socks5]"
                echo "BindAddress = 127.0.0.1:${toString config.my.services.networking.cloudflare-warp.port}"
              } >> wgcf-profile.conf

              echo "==> [wireproxy-warp] Pendaftaran dan pembuatan konfigurasi selesai."
            else
              echo "==> [wireproxy-warp] Profil ditemukan. Menggunakan konfigurasi yang ada."
            fi

            # Memastikan KeepAlive = 15 terpasang di bawah [Peer] untuk stabilitas auto-reconnect
            if [[ -f wgcf-profile.conf ]] && ! grep -q "KeepAlive" wgcf-profile.conf; then
              sed -i '/\[Peer\]/a KeepAlive = 15' wgcf-profile.conf
            fi
          ''
          [
            pkgs.coreutils
            pkgs.wgcf
            pkgs.gnused
            pkgs.gnugrep
          ];
    in
    {
      environment.systemPackages = [
        pkgs.wireproxy
        pkgs.wgcf
      ];

      systemd.services.wireproxy-warp = {
        description = "Wireproxy Cloudflare WARP SOCKS5 Proxy";
        onFailure = [ "status-alert@wireproxy-warp.service" ];
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        restartIfChanged = false;

        serviceConfig = {
          Type = "simple";
          DynamicUser = true;
          StateDirectory = "wireproxy-warp";
          StateDirectoryMode = "0700";
          LogLevelMax = "err";

          ExecStartPre = "${warpSetupScript}";
          ExecStart = "${pkgs.wireproxy}/bin/wireproxy --silent -c \${STATE_DIRECTORY}/wgcf-profile.conf";
          Restart = "always";
          RestartSec = "10s";
        };
      };
    };
}
