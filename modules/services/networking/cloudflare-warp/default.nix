{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "services.networking.cloudflare-warp";
  description = "Wireproxy based Cloudflare WARP service (In-Memory Generation)";

  nixosConfig = {
    environment.systemPackages = [
      pkgs.wireproxy
      pkgs.wgcf
    ];

    systemd.services.wireproxy-warp = {
      description = "Wireproxy Cloudflare WARP SOCKS5 Proxy";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      restartIfChanged = false;

      serviceConfig = {
        Type = "simple";
        DynamicUser = true;
        # Simpan konfigurasi secara persisten di var/lib/private/wireproxy-warp
        StateDirectory = "wireproxy-warp";
        StateDirectoryMode = "0700";

        # Sembunyikan log Info/Debug dari journalctl
        LogLevelMax = "err";

        ExecStartPre = pkgs.writeShellScript "generate-warp-config" ''
          cd "$STATE_DIRECTORY"

          if [[ ! -f wgcf-profile.conf ]]; then
            echo "==> [wireproxy-warp] Berkas profil tidak ditemukan. Memulai pendaftaran akun baru..."
            rm -f wgcf-profile.conf.tmp wgcf-account.toml
            
            while true; do
              if [[ ! -f wgcf-account.toml ]]; then
                ${pkgs.wgcf}/bin/wgcf register --accept-tos >/dev/null 2>&1 || { sleep 2; continue; }
              fi
              ${pkgs.wgcf}/bin/wgcf generate >/dev/null 2>&1 && break
              sleep 2
            done
            
            # Tambahkan konfigurasi SOCKS5 secara atomik menggunakan berkas sementara
            mv wgcf-profile.conf wgcf-profile.conf.tmp
            echo "" >> wgcf-profile.conf.tmp
            echo "[Socks5]" >> wgcf-profile.conf.tmp
            echo "BindAddress = 127.0.0.1:40000" >> wgcf-profile.conf.tmp
            mv wgcf-profile.conf.tmp wgcf-profile.conf
            echo "==> [wireproxy-warp] Pendaftaran dan pembuatan konfigurasi selesai."
          else
            echo "==> [wireproxy-warp] Profil ditemukan. Menggunakan konfigurasi yang ada."
          fi

          # Ensure KeepAlive = 15 is set under [Peer] to auto-reconnect WireGuard on boot network fluctuations
          if [[ -f wgcf-profile.conf ]] && ! grep -q "KeepAlive" wgcf-profile.conf; then
            ${pkgs.gnused}/bin/sed -i '/\[Peer\]/a KeepAlive = 15' wgcf-profile.conf
          fi
        '';

        ExecStart = "${pkgs.wireproxy}/bin/wireproxy --silent -c \${STATE_DIRECTORY}/wgcf-profile.conf";
        Restart = "always";
        RestartSec = "10s";
      };
    };
  };
}
