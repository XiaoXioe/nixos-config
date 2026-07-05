{
  pkgs,
  inputs,
  selfLib,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;

  ssh-mcp-pkg = inputs.nix-mcp.packages.${system}.ssh-mcp;
  codebase-memory-mcp-pkg = inputs.nix-mcp.packages.${system}.codebase-memory-mcp;
  google-colab-mcp-pkg = inputs.nix-mcp.packages.${system}.google-colab-mcp;
  telegram-mcp-pkg = inputs.nix-mcp.packages.${system}.telegram-mcp;
  github-mcp-server-pkg = inputs.nix-mcp.packages.${system}.github-mcp-server;

  makeSshMcp =
    {
      host,
      port ? 22,
      user,
      key ? "id_ed25519",
      homeDir,
    }:
    {
      command = "${ssh-mcp-pkg}/bin/ssh-mcp";
      args = [
        "--host=${host}"
        "--port=${toString port}"
        "--user=${user}"
        "--key=${homeDir}/.ssh/${key}"
        "--timeout=3000"
      ];
    };
in
selfLib.mkModule {
  name = "ai.mcp";
  description = "Nix-native Model Context Protocol (MCP) servers and configuration";

  hmConfig = hmOpts: {
    home = {
      packages = [
        ssh-mcp-pkg
        codebase-memory-mcp-pkg
        google-colab-mcp-pkg
        telegram-mcp-pkg
        github-mcp-server-pkg
        pkgs.mcp-nixos
      ];

      activation.setupMcpConfig = hmOpts.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        # Path referensi
        TOKEN_PATH="${hmOpts.osConfig.sops.secrets."cloudflare-token".path}"
        BASE_CONF="$HOME/.gemini/config/mcp_config_base.json"
        FINAL_CONF="$HOME/.gemini/config/mcp_config.json"

        # Pastikan direktori tujuan ada
        mkdir -p "$HOME/.gemini/config"

        # Jika file token SOPS berhasil didekripsi, gabungkan konfigurasi
        if [ -f "$TOKEN_PATH" ]; then
          CF_TOKEN=$(cat "$TOKEN_PATH")
          
          # Gunakan jq untuk menambahkan server Cloudflare beserta Header Autentikasi
          ${pkgs.jq}/bin/jq --arg token "Bearer $CF_TOKEN" \
            '.mcpServers += {
              "cloudflare-api": {
                "url": "https://mcp.cloudflare.com/mcp",
                "headers": {
                  "Authorization": $token
                }
              }
            }' "$BASE_CONF" > "$FINAL_CONF"
             
          # Kunci izin file final agar hanya bisa dibaca oleh Anda
          chmod 600 "$FINAL_CONF"
        else
          # Jika token tidak ada, gunakan konfigurasi dasar saja
          cp "$BASE_CONF" "$FINAL_CONF"
          chmod 600 "$FINAL_CONF"
        fi
      '';
    };

    home.file.".gemini/config/mcp_config_base.json".text = builtins.toJSON {
      mcpServers = {
        ssh_openwrt_old = makeSshMcp {
          host = "192.168.5.1";
          user = "root";
          key = "id_rsa_compat";
          homeDir = hmOpts.config.home.homeDirectory;
        };

        ssh_stb = makeSshMcp {
          host = "192.168.5.207";
          user = "klein";
          homeDir = hmOpts.config.home.homeDirectory;
        };

        ssh_mido = makeSshMcp {
          host = "192.168.5.185";
          user = "klein";
          homeDir = hmOpts.config.home.homeDirectory;
        };

        github = {
          command = "${pkgs.bash}/bin/bash";
          args = [
            "-c"
            "GITHUB_PERSONAL_ACCESS_TOKEN=$(cat ${
              hmOpts.osConfig.sops.secrets."github-access-token".path
            }) ${github-mcp-server-pkg}/bin/github-mcp-server stdio"
          ];
        };

        "codebase-memory-mcp" = {
          command = "${codebase-memory-mcp-pkg}/bin/codebase-memory-mcp";
          args = [ ];
          env = {
            CBM_CACHE_DIR = "${hmOpts.config.home.homeDirectory}/.agents/codebase_memory";
          };
        };

        nixos = {
          command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
          args = [ ];
        };

        "google-colab-mcp" = {
          command = "${google-colab-mcp-pkg}/bin/colab-mcp";
          args = [ ];
        };

        "telegram-mcp" = {
          command = "${telegram-mcp-pkg}/bin/telegram-mcp";
          args = [ "serve" ];
        };
      };
    };
  };
}
