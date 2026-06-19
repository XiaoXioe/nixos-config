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

  codebase-memory-mcp-pkg = pkgs.stdenv.mkDerivation rec {
    pname = "codebase-memory-mcp";
    version = "0.8.1";

    src = pkgs.fetchurl {
      url = "https://github.com/DeusData/codebase-memory-mcp/releases/download/v${version}/codebase-memory-mcp-linux-amd64.tar.gz";

      sha256 = "sha256-29O5Lqhw7yQLYwWfJr2hUBX3bvmXiTG+vDoPnQlHCXM=";
    };

    sourceRoot = ".";

    installPhase = ''
      mkdir -p $out/bin
      # Menyalin biner yang diekstrak ke direktori /bin lingkungan Nix
      cp codebase-memory-mcp $out/bin/
      chmod +x $out/bin/codebase-memory-mcp
    '';
  };
in
selfLib.mkModule {
  name = "ai.tools";
  description = "AI development tools and Model Context Protocol (MCP) configuration";

  hmConfig =
    {
      config,
      lib,
      osConfig,
      ...
    }:
    {
      home = {
        packages = [
          antigravity-ide
          antigravity-cli
          pkgs.gemini-cli
          claude-code
          pkgs.aider-chat
          codex-cli
          codebase-memory-mcp-pkg
        ];

        activation.setupMcpConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          # Path referensi
          TOKEN_PATH="${osConfig.sops.secrets."cloudflare-token".path}"
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
                "codebase-memory-mcp": {
                  "command": "${codebase-memory-mcp-pkg}/bin/codebase-memory-mcp",
                  "args": [],
                  "env": {
                    "CBM_CACHE_DIR": "${config.home.homeDirectory}/.agents/codebase_memory"
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
              host = "192.168.5.185";
              user = "klein";
            };

            # ghidra = {
            #   command = "${pkgs.bash}/bin/bash";
            #   args = [
            #     "-c"
            #     "GHIDRA_INSTALL_DIR=${pkgs.ghidra}/lib/ghidra JAVA_HOME=${pkgs.jdk} LD_LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib:$LD_LIBRARY_PATH ${pkgs.uv}/bin/uvx --from pyghidra-mcp pyghidra-mcp"
            #   ];
            # };

            github = {
              command = "${pkgs.bash}/bin/bash";
              args = [
                "-c"
                "GITHUB_PERSONAL_ACCESS_TOKEN=$(cat ${
                  osConfig.sops.secrets."github-access-token".path
                }) ${pkgs.nodejs}/bin/npx -y @modelcontextprotocol/server-github"
              ];
            };

            sqlite = {
              command = "${pkgs.uv}/bin/uvx";
              args = [
                "mcp-server-sqlite"
                "--db-path"
                "${config.home.homeDirectory}/.gemini/main.db"
              ];
            };

            memory = {
              command = "${pkgs.nodejs}/bin/npx";
              args = [
                "-y"
                "@modelcontextprotocol/server-memory"
              ];
              env = {
                MEMORY_FILE_PATH = "${config.home.homeDirectory}/.gemini/memory.json";
              };
            };

            fetch = {
              command = "${pkgs.nodejs}/bin/npx";
              args = [
                "-y"
                "@modelcontextprotocol/server-fetch"
              ];
            };
          };
        };
      };
    };
}
