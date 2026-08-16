{
  config,
  pkgs,
  lib,
  inputs,
  selfLib,
  ...
}:

let
  system = pkgs.stdenv.hostPlatform.system;
  userName = config.my.user.name;
  homeDir = "/home/${userName}";
  tavilyKeyPath = config.sops.secrets."tavily-api-key".path;

  # Flake package inputs
  nixMcpPkgs = inputs.nix-mcp.packages.${system};
  mcpPkgs = {
    inherit (nixMcpPkgs)
      codebase-memory-mcp
      google-colab-mcp
      telegram-mcp
      tavily-mcp
      scrapling
      agentmemory
      ;
    mcp-nixos = inputs.mcp-nixos.packages.${system}.default;
  };

  # ── Unified MCP Server Specification ─────────────────────────────────────────
  commonMcpServers = {
    nixos = {
      command = "${mcpPkgs.mcp-nixos}/bin/mcp-nixos";
    };
    codebase-memory-mcp = {
      command = "${mcpPkgs.codebase-memory-mcp}/bin/codebase-memory-mcp";
      env = {
        CBM_CACHE_DIR = "${homeDir}/.agents/codebase_memory";
      };
    };
    google-colab-mcp = {
      command = "${mcpPkgs.google-colab-mcp}/bin/colab-mcp";
    };
    telegram-mcp = {
      command = "${mcpPkgs.telegram-mcp}/bin/telegram-mcp";
    };
    scrapling = {
      command = "${mcpPkgs.scrapling}/bin/scrapling";
      args = [ "mcp" ];
      env = {
        SCRAPLING_EXECUTABLE_PATH = "/etc/profiles/per-user/${userName}/bin/chromium";
      };
    };
    agentmemory = {
      command = "${mcpPkgs.agentmemory}/bin/agentmemory-mcp";
      env = {
        AGENTMEMORY_URL = "http://127.0.0.1:3111";
        AGENTMEMORY_DATA_DIR = "${homeDir}/.agentmemory";
        AGENTMEMORY_TOOLS = "all";
      };
    };
  };

  # Transformer: Ubah spesifikasi umum ke format OpenCode ({ type = "local"; command = [...]; environment = {...}; })
  toOpencodeLocal =
    spec:
    lib.mapAttrs (
      _: s:
      {
        type = "local";
        command = [ s.command ] ++ (s.args or [ ]);
      }
      // lib.optionalAttrs (s ? env) {
        environment = s.env;
      }
    ) spec;

  # Transformer: Ubah spesifikasi umum ke format Gemini CLI / Antigravity ({ command = "..."; args = [...]; env = {...}; })
  toGeminiLocal =
    spec:
    lib.mapAttrs (
      _: s:
      {
        inherit (s) command;
        args = s.args or [ ];
      }
      // lib.optionalAttrs (s ? env) {
        inherit (s) env;
      }
    ) spec;

  # Konfigurasi lengkap OpenCode (termasuk Tavily dengan {file:...})
  opencodeMcpConfig = toOpencodeLocal commonMcpServers // {
    tavily = {
      type = "local";
      command = [ "${mcpPkgs.tavily-mcp}/bin/tavily-mcp" ];
      environment = {
        TAVILY_API_KEY = "{file:${tavilyKeyPath}}";
      };
    };
  };

  # Konfigurasi lengkap Gemini / Antigravity (termasuk Tavily & Cloudflare API via sops placeholder)
  geminiMcpConfig = {
    mcpServers = toGeminiLocal commonMcpServers // {
      tavily = {
        command = "${mcpPkgs.tavily-mcp}/bin/tavily-mcp";
        args = [ ];
        env = {
          TAVILY_API_KEY = config.sops.placeholder."tavily-api-key";
        };
      };
      cloudflare-api = {
        url = "https://mcp.cloudflare.com/mcp";
        headers = {
          Authorization = "Bearer ${config.sops.placeholder.cloudflare-token}";
        };
      };
    };
  };

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
    # 1. Dekripsi rahasia menggunakan sops-nix
    sops.secrets = {
      "tavily-api-key" = {
        sopsFile = ./secrets.yaml;
        owner = userName;
        mode = "0400";
      };
      "cloudflare-token" = {
        sopsFile = ./secrets.yaml;
        owner = userName;
        mode = "0400";
      };
    };

    # 2. Buat direktori tujuan untuk mcp_config.json dan agentmemory dengan kepemilikan yang tepat
    systemd.tmpfiles.rules = [
      "d ${homeDir}/.gemini 0755 ${userName} users - -"
      "d ${homeDir}/.gemini/config 0755 ${userName} users - -"
      "d ${homeDir}/.agentmemory 0755 ${userName} users - -"
    ];

    # 3. Buat berkas mcp_config.json secara deklaratif menggunakan sops.templates
    sops.templates."mcp_config.json" = {
      content = builtins.toJSON geminiMcpConfig;
      path = "${homeDir}/.gemini/config/mcp_config.json";
      owner = userName;
      mode = "0600";
    };
  };

  hmConfig =
    { pkgs, lib, ... }:
    {
      # activation murni hanya untuk mengelola opencode.json agar tetap MUTABLE
      home.activation.setupMcpConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        OPENCODE_CONF="$HOME/.config/opencode/opencode.json"

        ${pkgs.coreutils}/bin/mkdir -p "$HOME/.config/opencode"

        MCP_JSON='${builtins.toJSON opencodeMcpConfig}'

        if [ -L "$OPENCODE_CONF" ]; then
          ${pkgs.coreutils}/bin/rm -f "$OPENCODE_CONF"
        fi

        if [ ! -f "$OPENCODE_CONF" ]; then
          ${pkgs.jq}/bin/jq -n --argjson mcp "$MCP_JSON" \
            '{ "$schema": "https://opencode.ai/config.json", "mcp": $mcp }' > "$OPENCODE_CONF"
        else
          ${pkgs.jq}/bin/jq --argjson mcp "$MCP_JSON" '.mcp = $mcp' "$OPENCODE_CONF" > "$OPENCODE_CONF.tmp" && \
          ${pkgs.coreutils}/bin/mv -f "$OPENCODE_CONF.tmp" "$OPENCODE_CONF"
        fi
        ${pkgs.coreutils}/bin/chmod 600 "$OPENCODE_CONF"
      '';

      systemd.user.services.agentmemory = {
        Unit = {
          Description = "AgentMemory Persistent Memory Engine & Web Viewer";
          After = [ "network.target" ];
        };
        Service = {
          WorkingDirectory = "%h/.agentmemory";
          ExecStart = "${mcpPkgs.agentmemory}/bin/agentmemory";
          Restart = "on-failure";
          RestartSec = 5;
          StandardOutput = "append:%h/.agentmemory/agentmemory.log";
          StandardError = "append:%h/.agentmemory/agentmemory.err.log";
          Environment = [
            "CI=1"
            "HOME=%h"
            "PATH=/etc/profiles/per-user/%u/bin:/run/current-system/sw/bin"
            "AGENTMEMORY_DATA_DIR=%h/.agentmemory"
            "CONSOLIDATION_ENABLED=true"
            "AGENTMEMORY_TOOLS=all"
            "AGENTMEMORY_SLOTS=true"
          ];
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };
    };
}
