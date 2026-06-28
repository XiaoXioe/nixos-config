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

      serviceConfig = {
        Type = "simple";
        DynamicUser = true;
        # Buat direktori runtime sementara di RAM (tmpfs) yang aman (chmod 700)
        RuntimeDirectory = "wireproxy-warp";
        RuntimeDirectoryMode = "0700";
        
        # Sembunyikan log Info/Debug dari journalctl
        LogLevelMax = "err";
        
        ExecStartPre = pkgs.writeShellScript "generate-warp-config" ''
          cd "$RUNTIME_DIRECTORY"
          
          # Hapus sisa konfigurasi jika ada dari restart sebelumnya
          rm -f wgcf-account.toml wgcf-profile.conf
          
          # Coba registrasi dan generate secara berulang sampai keduanya sukses
          while true; do
            ${pkgs.wgcf}/bin/wgcf register --accept-tos >/dev/null 2>&1 || { sleep 2; continue; }
            ${pkgs.wgcf}/bin/wgcf generate >/dev/null 2>&1 && break
            sleep 2
          done
          
          # Tambahkan konfigurasi SOCKS5 agar dikenali oleh wireproxy
          echo "" >> wgcf-profile.conf
          echo "[Socks5]" >> wgcf-profile.conf
          echo "BindAddress = 127.0.0.1:40000" >> wgcf-profile.conf
        '';

        ExecStart = "${pkgs.wireproxy}/bin/wireproxy --silent -c \${RUNTIME_DIRECTORY}/wgcf-profile.conf";
        Restart = "always";
        RestartSec = "10s";
      };
    };
  };
}
