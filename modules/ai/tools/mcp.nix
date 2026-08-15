{
  config,
  pkgs,
  inputs,
  selfLib,
  ...
}:

let
  system = pkgs.stdenv.hostPlatform.system;

  # Packages dari flake input nix-mcp
  codebase-memory-mcp-pkg = inputs.nix-mcp.packages.${system}.codebase-memory-mcp;
  google-colab-mcp-pkg = inputs.nix-mcp.packages.${system}.google-colab-mcp;
  telegram-mcp-pkg = inputs.nix-mcp.packages.${system}.telegram-mcp;
  tavily-mcp-pkg = inputs.nix-mcp.packages.${system}.tavily-mcp;
  sequential-thinking-pkg = inputs.nix-mcp.packages.${system}.sequential-thinking;
  mcp-nixos-pkg = inputs.mcp-nixos.packages.${system}.default;
  scrapling-mcp-pkg = inputs.nix-mcp.packages.${system}.scrapling;
  agentmemory-pkg = inputs.nix-mcp.packages.${system}.agentmemory;

  homeDir = "/home/${config.my.user.name}";
  tavilyKeyPath = config.sops.secrets."tavily-api-key".path;

  # Konfigurasi eksplisit untuk OpenCode (karena bersifat lokal & mutable)
  opencodeMcpConfig = {
    nixos = {
      type = "local";
      command = [ "${mcp-nixos-pkg}/bin/mcp-nixos" ];
    };
    codebase-memory-mcp = {
      type = "local";
      command = [ "${codebase-memory-mcp-pkg}/bin/codebase-memory-mcp" ];
      environment = {
        CBM_CACHE_DIR = "${homeDir}/.agents/codebase_memory";
      };
    };
    google-colab-mcp = {
      type = "local";
      command = [ "${google-colab-mcp-pkg}/bin/colab-mcp" ];
    };
    telegram-mcp = {
      type = "local";
      command = [ "${telegram-mcp-pkg}/bin/telegram-mcp" ];
    };
    tavily = {
      type = "local";
      command = [ "${tavily-mcp-pkg}/bin/tavily-mcp" ];
      environment = {
        TAVILY_API_KEY = "{file:${tavilyKeyPath}}";
      };
    };
    sequential-thinking = {
      type = "local";
      command = [ "${sequential-thinking-pkg}/bin/mcp-server-sequential-thinking" ];
    };
    scrapling = {
      type = "local";
      command = [ "${scrapling-mcp-pkg}/bin/scrapling" ];
      environment = {
        SCRAPLING_EXECUTABLE_PATH = "/etc/profiles/per-user/${config.my.user.name}/bin/chromium";
      };
    };
    agentmemory = {
      type = "local";
      command = [ "${agentmemory-pkg}/bin/agentmemory-mcp" ];
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
        owner = config.my.user.name;
        mode = "0400";
      };
      "cloudflare-token" = {
        sopsFile = ./secrets.yaml;
        owner = config.my.user.name;
        mode = "0400";
      };
    };

    # 2. Buat direktori tujuan untuk mcp_config.json dengan kepemilikan yang tepat
    systemd.tmpfiles.rules = [
      "d ${homeDir}/.gemini 0755 ${config.my.user.name} users - -"
      "d ${homeDir}/.gemini/config 0755 ${config.my.user.name} users - -"
    ];

    # 3. Buat berkas mcp_config.json secara deklaratif menggunakan sops.templates
    sops.templates."mcp_config.json" = {
      content = builtins.toJSON {
        mcpServers = {
          nixos = {
            command = "${mcp-nixos-pkg}/bin/mcp-nixos";
            args = [ ];
          };
          codebase-memory-mcp = {
            command = "${codebase-memory-mcp-pkg}/bin/codebase-memory-mcp";
            args = [ ];
            env = {
              CBM_CACHE_DIR = "${homeDir}/.agents/codebase_memory";
            };
          };
          google-colab-mcp = {
            command = "${google-colab-mcp-pkg}/bin/colab-mcp";
            args = [ ];
          };
          telegram-mcp = {
            command = "${telegram-mcp-pkg}/bin/telegram-mcp";
            args = [ ];
          };
          tavily = {
            command = "${tavily-mcp-pkg}/bin/tavily-mcp";
            args = [ ];
            env = {
              TAVILY_API_KEY = config.sops.placeholder."tavily-api-key";
            };
          };
          sequential-thinking = {
            command = "${sequential-thinking-pkg}/bin/mcp-server-sequential-thinking";
            args = [ ];
          };
          scrapling = {
            command = "${scrapling-mcp-pkg}/bin/scrapling";
            args = [ "mcp" ];
            env = {
              SCRAPLING_EXECUTABLE_PATH = "/etc/profiles/per-user/${config.my.user.name}/bin/chromium";
            };
          };
          agentmemory = {
            command = "${agentmemory-pkg}/bin/agentmemory-mcp";
            args = [ ];
          };
          cloudflare-api = {
            url = "https://mcp.cloudflare.com/mcp";
            headers = {
              Authorization = "Bearer ${config.sops.placeholder.cloudflare-token}";
            };
          };
        };
      };
      path = "${homeDir}/.gemini/config/mcp_config.json";
      owner = config.my.user.name;
      mode = "0600";
    };
  };

  hmConfig =
    {
      pkgs,
      lib,
      ...
    }:
    let
      scriptsDir = "${agentmemory-pkg}/lib/agentmemory/node_modules/@agentmemory/agentmemory/plugin/scripts";
    in
    {
      home = {
        packages = [
          codebase-memory-mcp-pkg
          google-colab-mcp-pkg
          telegram-mcp-pkg
          tavily-mcp-pkg
          sequential-thinking-pkg
          mcp-nixos-pkg
          scrapling-mcp-pkg
          agentmemory-pkg
        ];

        # Konfigurasi Hooks deklaratif untuk Google Antigravity
        file.".gemini/config/hooks.json".text = builtins.toJSON {
          agentmemory = {
            enabled = true;
            SessionStart = [
              {
                type = "command";
                command = "${pkgs.nodejs}/bin/node ${scriptsDir}/session-start.mjs";
              }
            ];
            PreInvocation = [
              {
                type = "command";
                command = "${pkgs.nodejs}/bin/node ${scriptsDir}/prompt-submit.mjs";
              }
              {
                type = "command";
                command = "${pkgs.nodejs}/bin/node ${scriptsDir}/pre-compact.mjs";
              }
            ];
            PostInvocation = [
              {
                type = "command";
                command = "${pkgs.nodejs}/bin/node ${scriptsDir}/session-end.mjs";
              }
            ];
            PreToolUse = [
              {
                matcher = ".*";
                hooks = [
                  {
                    type = "command";
                    command = "${pkgs.nodejs}/bin/node ${scriptsDir}/pre-tool-use.mjs";
                  }
                ];
              }
              {
                matcher = "invoke_subagent|define_subagent";
                hooks = [
                  {
                    type = "command";
                    command = "${pkgs.nodejs}/bin/node ${scriptsDir}/subagent-start.mjs";
                  }
                ];
              }
            ];
            PostToolUse = [
              {
                matcher = ".*";
                hooks = [
                  {
                    type = "command";
                    command = "${pkgs.nodejs}/bin/node ${scriptsDir}/post-tool-use.mjs";
                  }
                  {
                    type = "command";
                    command = "${pkgs.nodejs}/bin/node ${scriptsDir}/post-tool-failure.mjs";
                  }
                ];
              }
              {
                matcher = "run_command";
                hooks = [
                  {
                    type = "command";
                    command = "${pkgs.nodejs}/bin/node ${scriptsDir}/post-commit.mjs";
                  }
                ];
              }
              {
                matcher = "invoke_subagent";
                hooks = [
                  {
                    type = "command";
                    command = "${pkgs.nodejs}/bin/node ${scriptsDir}/subagent-stop.mjs";
                  }
                ];
              }
            ];
            Stop = [
              {
                type = "command";
                command = "${pkgs.nodejs}/bin/node ${scriptsDir}/stop.mjs";
              }
              {
                type = "command";
                command = "${pkgs.nodejs}/bin/node ${scriptsDir}/task-completed.mjs";
              }
            ];
          };
        };

        # activation murni hanya untuk mengelola opencode.json agar tetap MUTABLE
        activation.setupMcpConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
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
      };

      systemd.user.services.agentmemory = {
        Unit = {
          Description = "AgentMemory Persistent Memory Engine & Web Viewer";
          After = [ "network.target" ];
        };
        Service = {
          ExecStart = "${agentmemory-pkg}/bin/agentmemory";
          Restart = "on-failure";
          RestartSec = 5;
          Environment = [
            "CI=1"
            "HOME=%h"
            "PATH=/etc/profiles/per-user/%u/bin:/run/current-system/sw/bin"
          ];
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };
    };
}
