{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.system.ghidra-mcp;

  # ==============================
  # AUTO-DOWNLOAD GHIDRA MCP
  # ==============================
  # Nix akan mengunduh file ini otomatis saat proses rebuild
  ghidraMcpRelease = pkgs.fetchzip {
    url = "https://github.com/starsong-consulting/GhydraMCP/releases/download/v2.2.0-rc.3/GhydraMCP-Complete-v2.2.0-rc.3-20260216-180506.zip";

    hash = "sha256-KUbLJaZKqasKKtPpzid2XqKm6a+RfdocMKvEuARP50Y=";

    stripRoot = false;
  };
in
{
  options.my.system.ghidra-mcp = {
    enable = selfLib.mkBoolOpt false "Ghidra-MCP Bridge settings";
  };

  config = lib.mkIf cfg.enable {
    # ==============================
    # CUSTOM SERVICE: GHIDRA-MCP-BRIDGE
    # ==============================
    systemd.services.ghidra-mcp-bridge = {
      description = "Ghidra MCP Bridge for AI Reverse Engineering";
      bindsTo = [ "ollama.service" ];
      after = [
        "network.target"
        "ollama.service"
      ];

      serviceConfig = {
        Type = "simple";
        User = config.my.user.name; # Menggunakan user utama secara dinamis
        Restart = "on-failure";
        RestartSec = "5s";
      };

      preStart = ''
        # 1. Siapkan folder kerja lokal
        mkdir -p /home/${config.my.user.name}/.local/share/ghidra-mcp-auto

        # 2. Salin otomatis script python dari Nix Store ke folder kerja
        # Menggunakan || true agar service tidak mati jika kebetulan kosong
        cp -f ${ghidraMcpRelease}/*.py /home/${config.my.user.name}/.local/share/ghidra-mcp-auto/ || true

        # 3. Salin juga file Ekstensi Ghidra ke folder Documents
        # Kita gunakan *.zip agar mendeteksi nama file apa pun tanpa peduli huruf besar/kecil
        mkdir -p /home/${config.my.user.name}/Documents/Tools
        cp -f ${ghidraMcpRelease}/*.zip /home/${config.my.user.name}/Documents/Tools/ 2>/dev/null || true
      '';

      script = ''
        export PATH="${pkgs.uv}/bin:$PATH"

        cd /home/${config.my.user.name}/.local/share/ghidra-mcp-auto

        # Cari file python apa pun yang memiliki 'mcp' di namanya
        PY_SCRIPT=$(ls *mcp*.py | head -n 1)
        uvx mcpo -- uv run "$PY_SCRIPT"
      '';
      wantedBy = lib.mkForce [ ];
    };

    systemd.services.ollama.wants = [ "ghidra-mcp-bridge.service" ];
  };
}
