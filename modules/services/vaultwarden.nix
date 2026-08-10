{
  config,
  pkgs,
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
      default = false;
      description = "Apakah pendaftaran akun baru diizinkan. Default false untuk keamanan personal instance.";
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Jalur ke berkas rahasia SOPS untuk ADMIN_TOKEN & SMTP";
    };
  };

  preservation = {
    persist = true;
    directories = [
      "/var/lib/vaultwarden"
      "/var/lib/caddy"
    ];
  };

  nixosConfig =
    let
      cfg = config.my.services.vaultwarden;

      # Buat sertifikat SSL self-signed lokal (Nix Store path) untuk localhost & 127.0.0.1
      # agar dapat dimasukkan ke security.pki.certificateFiles saat build-time tanpa error missing file.
      localCert =
        pkgs.runCommand "vaultwarden-local-cert"
          {
            nativeBuildInputs = [ pkgs.openssl ];
          }
          ''
            mkdir -p $out
            openssl req -x509 -newkey rsa:2048 -sha256 -days 3650 -nodes \
              -keyout $out/cert.key -out $out/cert.crt \
              -subj "/CN=localhost" \
              -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"
          '';
    in
    {
      services.vaultwarden = {
        enable = true;
      }
      // (lib.optionalAttrs (cfg.environmentFile != null) {
        inherit (cfg) environmentFile;
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

      # Caddy Reverse Proxy menggunakan sertifikat lokal Nix Store untuk localhost & 127.0.0.1
      services.caddy = lib.mkIf cfg.enableLocalHttps {
        enable = true;
        virtualHosts."https://localhost:${toString cfg.httpsPort}, https://127.0.0.1:${toString cfg.httpsPort}".extraConfig =
          ''
            tls ${localCert}/cert.crt ${localCert}/cert.key
            reverse_proxy 127.0.0.1:${toString cfg.port}
          '';
      };

      # Daftarkan sertifikat SSL ke Trusted System Certificates NixOS
      security.pki.certificateFiles = lib.mkIf cfg.enableLocalHttps [
        "${localCert}/cert.crt"
      ];

      # Membuka port di firewall NixOS
      networking.firewall.allowedTCPPorts = [
        cfg.port
        cfg.websocketPort
      ]
      ++ (lib.optional cfg.enableLocalHttps cfg.httpsPort);
    };
}
