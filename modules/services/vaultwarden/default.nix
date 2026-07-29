{
  config,
  lib,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "services.vaultwarden";
  description = "Vaultwarden Bitwarden-compatible password manager server with Caddy Local HTTPS";

  options = {
    port = lib.mkOption {
      type = lib.types.port;
      default = 8222;
      description = "Port HTTP internal yang digunakan oleh server Vaultwarden";
    };

    websocketPort = lib.mkOption {
      type = lib.types.port;
      default = 3012;
      description = "Port WebSocket untuk notifikasi real-time Vaultwarden";
    };

    httpsPort = lib.mkOption {
      type = lib.types.port;
      default = 8443;
      description = "Port HTTPS lokal (Caddy reverse proxy)";
    };

    enableLocalHttps = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Apakah mengaktifkan Caddy Reverse Proxy untuk HTTPS lokal otomatis";
    };

    domain = lib.mkOption {
      type = lib.types.str;
      default = "https://localhost:8443";
      description = "URL/Domain utama Vaultwarden (Default: https://localhost:8443)";
    };

    allowSignups = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Apakah pendaftaran akun baru diizinkan";
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Jalur ke berkas rahasia SOPS untuk ADMIN_TOKEN & SMTP";
    };
  };

  nixosConfig =
    let
      cfg = config.my.services.vaultwarden;
    in
    {
      # Mempertahankan data Vaultwarden & sertifikat Caddy dari wipe reboot Impermanence
      my.hardware.preservation.extraDirectories = [
        "/var/lib/vaultwarden"
        "/var/lib/caddy"
      ];

      services.vaultwarden = {
        enable = true;
      }
      // (lib.optionalAttrs (cfg.environmentFile != null) {
        environmentFile = cfg.environmentFile;
      })
      // {
        config = {
          ROCKET_PORT = cfg.port;
          WEBSOCKET_ENABLED = true;
          WEBSOCKET_PORT = cfg.websocketPort;
          DOMAIN = cfg.domain;
          SIGNUPS_ALLOWED = cfg.allowSignups;
          INVITATIONS_ALLOWED = true;
          SHOW_PASSWORD_HINT = false;
        };
      };

      # Caddy Reverse Proxy menggunakan tls internal otomatis untuk localhost & 127.0.0.1
      services.caddy = lib.mkIf cfg.enableLocalHttps {
        enable = true;
        virtualHosts."https://localhost:${toString cfg.httpsPort}, https://127.0.0.1:${toString cfg.httpsPort}".extraConfig =
          ''
            tls internal
            reverse_proxy 127.0.0.1:${toString cfg.port}
          '';
      };

      # Membuka port di firewall NixOS
      networking.firewall.allowedTCPPorts = [
        cfg.port
        cfg.websocketPort
      ]
      ++ (lib.optional cfg.enableLocalHttps cfg.httpsPort);
    };
}
