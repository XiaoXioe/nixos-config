{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:

let
  cfg = config.my.services.documents.stirling-pdf;
in
selfLib.mkModule {
  name = "services.documents.stirling-pdf";
  description = "Stirling-PDF local service and desktop tool integration";

  options = {
    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Local port for Stirling-PDF web server and MCP endpoint";
    };

    enableDesktop = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to install Stirling-PDF native desktop application";
    };

    locale = lib.mkOption {
      type = lib.types.str;
      default = "id-ID";
      description = "Default UI language for Stirling-PDF";
    };
  };

  preservation = {
    directories = [
      "/var/lib/stirling-pdf"
    ];
  };

  nixosConfig = {
    # 1. Background Service Systemd (Local Engine)
    services.stirling-pdf = {
      enable = true;
      environment = {
        SERVER_PORT = toString cfg.port;
        SECURITY_ENABLELOGIN = "false"; # Akses instan bebas auth untuk localhost
        MCP_ENABLED = "true"; # Mengaktifkan MCP endpoint (/mcp)
        SYSTEM_DEFAULTLOCALE = cfg.locale;
      };
    };

    # 2. Desktop GUI App
    environment.systemPackages = lib.optionals cfg.enableDesktop [
      pkgs.stirling-pdf-desktop
    ];
  };
}
