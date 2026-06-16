{
  pkgs,
  config,
  inputs,
  selfLib,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  antigravity-cli = inputs.antigravity-nix.packages.${system}.google-antigravity-cli;
  antigravity-ide = inputs.antigravity-nix.packages.${system}.google-antigravity-ide;
  codex-cli = inputs.codex-cli.packages.${system}.default;
  claude-code = inputs.claude-code.packages.${system}.default;

  makeSshMcp =
    {
      host,
      port ? 22,
      user,
      key ? "id_ed25519",
    }:
    {
      command = "${pkgs.nodejs}/bin/npx";
      args = [
        "-y"
        "ssh-mcp"
        "--host=${host}"
        "--port=${toString port}"
        "--user=${user}"
        "--key=/home/${config.my.user.name}/.ssh/${key}"
        "--timeout=60000"
      ];
    };
in
selfLib.mkModule {
  name = "ai.tools";
  description = "AI development tools and Model Context Protocol (MCP) configuration";

  hmConfig = { lib, ... }: {
    home = {
      packages = [
        antigravity-ide
        antigravity-cli
        pkgs.gemini-cli
        claude-code
        pkgs.aider-chat
        codex-cli
      ];

      activation.setupMcpConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        # Path referensi
        TOKEN_PATH="${config.sops.secrets."cloudflare-token".path}"
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
                "url": "https://mcp.cloudflare.com/sse",
                "headers": {
                  "Authorization": $token
                }
              },
              "memory": {
                "command": "${pkgs.nodejs}/bin/npx",
                "args": [
                  "-y",
                  "@modelcontextprotocol/server-memory"
                ]
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

      file.".gemini/config/mcp_config_base.json".text = builtins.toJSON {
        mcpServers = {
          ssh_openwrt_old = makeSshMcp {
            host = "192.168.5.1";
            user = "root";
            key = "id_rsa_compat";
          };

          ssh_nikel_termux = makeSshMcp {
            host = "192.168.5.187";
            port = 8022;
            user = "u0_a90";
          };

          ssh_arch_nikel = makeSshMcp {
            host = "192.168.5.187";
            port = 4242;
            user = "arch-nikel";
          };

          ssh_stb = makeSshMcp {
            host = "192.168.5.207";
            user = "klein";
          };

          ssh_mido = makeSshMcp {
            host = "192.168.5.224";
            user = "klein";
          };

          ghidra = {
            command = "${pkgs.uv}/bin/uvx";
            args = [
              "--from"
              "pyghidra-mcp"
              "pyghidra-mcp"
            ];
          };

          github = {
            command = "${pkgs.bash}/bin/bash";
            args = [
              "-c"
              "GITHUB_PERSONAL_ACCESS_TOKEN=$(cat ${
                config.sops.secrets."github-access-token".path
              }) ${pkgs.nodejs}/bin/npx -y @modelcontextprotocol/server-github"
            ];
          };

          sqlite = {
            command = "${pkgs.uv}/bin/uvx";
            args = [
              "mcp-server-sqlite"
              "--db-path"
              "/home/${config.my.user.name}/.gemini/main.db"
            ];
          };
        };
      };
    };
  };
}
