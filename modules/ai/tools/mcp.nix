{
  config,
  pkgs,
  inputs,
  selfLib,
  ...
}:

let
  system = pkgs.stdenv.hostPlatform.system;

  # ssh-mcp-pkg = inputs.nix-mcp.packages.${system}.ssh-mcp;
  codebase-memory-mcp-pkg = inputs.nix-mcp.packages.${system}.codebase-memory-mcp;
  google-colab-mcp-pkg = inputs.nix-mcp.packages.${system}.google-colab-mcp;
  telegram-mcp-pkg = inputs.nix-mcp.packages.${system}.telegram-mcp;
  # github-mcp-server-pkg = inputs.nix-mcp.packages.${system}.github-mcp-server;
  tavily-mcp-pkg = inputs.nix-mcp.packages.${system}.tavily-mcp;
  agentmemory-pkg = inputs.nix-mcp.packages.${system}.agentmemory;
  sequential-thinking-pkg = inputs.nix-mcp.packages.${system}.sequential-thinking;
  mcp-nixos-pkg = inputs.mcp-nixos.packages.${system}.default;

in
selfLib.mkModule {
  name = "ai.tools.mcp";
  description = "Nix-native Model Context Protocol (MCP) servers and configuration";

  preservation = {
    persist = true;
    userDirectories = [
      ".agents"
      ".agentmemory"
      ".telegram-mcp"
      {
        directory = ".mcp-colab";
        mode = "0700";
      }
    ];
  };

  nixosConfig = {
    sops.secrets = {
      "tavily-api-key" = {
        sopsFile = ./secrets.yaml;
        owner = config.my.user.name;
        mode = "0400";
      };
      "cloudflare-token" = {
        sopsFile = ./secrets.yaml;
        owner = config.my.user.name;
        mode = "0400";
      };
    };
  };

  hmConfig =
    {
      config,
      pkgs,
      lib,
      osConfig,
      ...
    }:
    let
      homeDir = config.home.homeDirectory;

      # Path rahasia sops-nix
      # githubTokenPath = osConfig.sops.secrets."github-access-token-1".path;
      tavilyKeyPath = osConfig.sops.secrets."tavily-api-key".path;
      cloudflareTokenPath = osConfig.sops.secrets."cloudflare-token".path;
      # dockerTokenPath = osConfig.sops.secrets."docker-token".path;

      execServers = {
        # github = {
        #   pkg = github-mcp-server-pkg;
        #   bin = "github-mcp-server";
        #   args = [ "stdio" ];
        #   geminiWrap = "[ -s \"${githubTokenPath}\" ] && export GITHUB_PERSONAL_ACCESS_TOKEN=$(cat ${githubTokenPath});";
        #   env = {
        #     GITHUB_PERSONAL_ACCESS_TOKEN = "{file:${githubTokenPath}}";
        #   };
        # };
        nixos = {
          pkg = mcp-nixos-pkg;
          bin = "mcp-nixos";
        };
        codebase-memory-mcp = {
          pkg = codebase-memory-mcp-pkg;
          bin = "codebase-memory-mcp";
          env = {
            CBM_CACHE_DIR = "${homeDir}/.agents/codebase_memory";
          };
        };
        google-colab-mcp = {
          pkg = google-colab-mcp-pkg;
          bin = "colab-mcp";
        };
        telegram-mcp = {
          pkg = telegram-mcp-pkg;
          bin = "telegram-mcp";
        };
        tavily = {
          pkg = tavily-mcp-pkg;
          bin = "tavily-mcp";
          geminiWrap = "[ -s \"${tavilyKeyPath}\" ] && export TAVILY_API_KEY=$(cat ${tavilyKeyPath});";
          env = {
            TAVILY_API_KEY = "{file:${tavilyKeyPath}}";
          };
        };
        # server-memory = {
        #   pkg = server-memory-pkg;
        #   bin = "mcp-server-memory";
        #   env = {
        #     MEMORY_FILE_PATH = "${homeDir}/.gemini/config/memory.json";
        #   };
        # };
        agentmemory = {
          pkg = agentmemory-pkg;
          bin = "agentmemory-mcp";
          env = {
            AGENTMEMORY_URL = "http://localhost:3111";
            # Expose all 51 MCP tools (default "all", but be explicit)
            AGENTMEMORY_TOOLS = "all";
          };
        };
        sequential-thinking = {
          pkg = sequential-thinking-pkg;
          bin = "mcp-server-sequential-thinking";
        };
      };

      opencodeExec = lib.mapAttrs (
        name: cfg:
        let
          base = {
            type = "local";
            command = [ "${cfg.pkg}/bin/${cfg.bin}" ] ++ (cfg.args or [ ]);
          };
        in
        if cfg ? env then base // { environment = cfg.env; } else base
      ) execServers;

      cloudflareCfg = {
        url = "https://mcp.cloudflare.com/mcp";
      };

      opencodeMcpConfig = opencodeExec;

      geminiExec = lib.mapAttrs (
        name: cfg:
        if cfg ? geminiWrap then
          {
            command = "${pkgs.bash}/bin/bash";
            args = [
              "-c"
              "${cfg.geminiWrap} exec ${cfg.pkg}/bin/${cfg.bin} ${lib.escapeShellArgs (cfg.args or [ ])}"
            ];
          }
        else
          {
            command = "${cfg.pkg}/bin/${cfg.bin}";
            args = cfg.args or [ ];
            env = cfg.env or { };
          }
      ) execServers;
    in
    {
      home = {
        packages = [
          # ssh-mcp-pkg
          codebase-memory-mcp-pkg
          google-colab-mcp-pkg
          telegram-mcp-pkg
          # github-mcp-server-pkg
          tavily-mcp-pkg
          # server-memory-pkg
          agentmemory-pkg
          sequential-thinking-pkg
          mcp-nixos-pkg
        ];

        # KRUSIAL: home.activation Diperlukan untuk:
        # 1. Menggabungkan secret token Cloudflare dari /run/user/1000/secrets/ ke mcp_config.json saat runtime.
        # 2. Menjaga opencode.json tetap MUTABLE agar OpenCode dapat mengedit tools/config tanpa error 'read-only filesystem'.
        activation.setupMcpConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          TOKEN_PATH="${cloudflareTokenPath}"
          BASE_CONF="$HOME/.gemini/config/mcp_config_base.json"
          FINAL_CONF="$HOME/.gemini/config/mcp_config.json"
          OPENCODE_CONF="$HOME/.config/opencode/opencode.json"

          ${pkgs.coreutils}/bin/mkdir -p "$HOME/.gemini/config"
          ${pkgs.coreutils}/bin/mkdir -p "$HOME/.config/opencode"

          if [ -f "$BASE_CONF" ]; then
            if [ -f "$TOKEN_PATH" ] && [ -s "$TOKEN_PATH" ]; then
              CF_TOKEN=$(${pkgs.coreutils}/bin/cat "$TOKEN_PATH")
              ${pkgs.jq}/bin/jq --arg token "Bearer $CF_TOKEN" \
                '.mcpServers += {
                  "cloudflare-api": {
                    "url": "${cloudflareCfg.url}",
                    "headers": {
                      "Authorization": $token
                    }
                  }
                }' "$BASE_CONF" > "$FINAL_CONF"
              ${pkgs.coreutils}/bin/chmod 600 "$FINAL_CONF"
            else
              ${pkgs.coreutils}/bin/cp "$BASE_CONF" "$FINAL_CONF"
              ${pkgs.coreutils}/bin/chmod 600 "$FINAL_CONF"
            fi
          fi

          # Menjaga opencode.json sebagai file yang dapat diubah (mutable) oleh CLI OpenCode
          MCP_JSON='${builtins.toJSON opencodeMcpConfig}'

          if [ -L "$OPENCODE_CONF" ]; then
            ${pkgs.coreutils}/bin/rm -f "$OPENCODE_CONF"
          fi

          if [ ! -f "$OPENCODE_CONF" ]; then
            ${pkgs.jq}/bin/jq -n --argjson mcp "$MCP_JSON" \
              '{ "$schema": "https://opencode.ai/config.json", "mcp": $mcp }' > "$OPENCODE_CONF"
          else
            ${pkgs.jq}/bin/jq --argjson mcp "$MCP_JSON" '.mcp = $mcp' "$OPENCODE_CONF" > "$OPENCODE_CONF.tmp" && ${pkgs.coreutils}/bin/mv -f "$OPENCODE_CONF.tmp" "$OPENCODE_CONF"
          fi
          ${pkgs.coreutils}/bin/chmod 600 "$OPENCODE_CONF"
        '';
      };

      home.file.".gemini/config/mcp_config_base.json".text = builtins.toJSON {
        mcpServers = geminiExec;
      };

      systemd.user.services.agentmemory = {
        Unit = {
          Description = "AgentMemory Daemon Server";
          After = [ "network.target" ];
        };
        Service = {
          WorkingDirectory = "${homeDir}/.agentmemory";
          ExecStart = "${agentmemory-pkg}/bin/agentmemory";
          Restart = "on-failure";
          RestartSec = "5s";
          Environment = [
            # Enable knowledge graph extraction (powers graph-traversal recall)
            "GRAPH_EXTRACTION_ENABLED=true"
            # Enable 4-tier consolidation pipeline
            "CONSOLIDATION_ENABLED=true"
            # Expose all 51 MCP tools to the daemon
            "AGENTMEMORY_TOOLS=all"
            # Enable memory slots (pinned scratchpad across sessions)
            "AGENTMEMORY_SLOTS=true"
          ];
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };
    };
}
