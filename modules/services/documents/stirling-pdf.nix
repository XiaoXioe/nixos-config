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
      default = false;
      description = "Whether to install Stirling-PDF native desktop application";
    };

    lightweight = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Exclude heavy dependencies like LibreOffice, OpenCV, and OCRmyPDF to save ~1.2+ GiB download";
    };

    locale = lib.mkOption {
      type = lib.types.str;
      default = "id-ID";
      description = "Default UI language for Stirling-PDF";
    };
  };

  preservation = {
    directories = [
      {
        directory = "/var/lib/private/stirling-pdf";
        mode = "0700";
      }
    ];
  };

  nixosConfig = {
    # 1. Background Service Systemd (Local Engine)
    services.stirling-pdf = {
      enable = true;
      package = selfLib.fetchCachePinned "stirling_pdf";
      environment = {
        SERVER_PORT = toString cfg.port;
        SECURITY_ENABLELOGIN = "false"; # Akses instan bebas auth untuk localhost
        MCP_ENABLED = "true"; # Mengaktifkan MCP endpoint (/mcp)
        MCP_AUTH_MODE = "apikey"; # Gunakan mode API Key untuk MCP endpoint
        SECURITY_CUSTOMGLOBALAPIKEY = "stirling-local-internal-mcp-key"; # Global API key untuk MCP internal
        SYSTEM_DEFAULTLOCALE = cfg.locale;
      };
    };

    systemd.services.stirling-pdf = {
      wantedBy = lib.mkForce [ ];
      restartIfChanged = false;
      path = lib.mkIf cfg.lightweight (
        lib.mkForce (
          with pkgs;
          [
            which
            qpdf
            poppler-utils
            ghostscript_headless
            tesseract
            pngquant
          ]
        )
      );
    };

    # 2. Desktop GUI App
    environment.systemPackages = lib.optionals cfg.enableDesktop [
      (selfLib.fetchCachePinned "stirling_pdf_desktop")
    ];
  };
}
