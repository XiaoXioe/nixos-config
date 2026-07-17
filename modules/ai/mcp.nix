{
  lib,
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
  tavily-mcp-pkg = inputs.nix-mcp.packages.${system}.tavily-mcp;

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

  # Adapter: Gemini → OpenCode format, tanpa duplikasi parameter
  makeOpenCodeSshMcp =
    args:
    let
      m = makeSshMcp args;
    in
    {
      type = "local";
      command = [ m.command ] ++ m.args;
      enabled = true;
    };
in
selfLib.mkModule {
  name = "ai.mcp";
  description = "Nix-native Model Context Protocol (MCP) servers and configuration";

  hmConfig =
    hmOpts:
    let
      homeDir = hmOpts.config.home.homeDirectory;

      # Secret paths (defined sekali, dipakai kedua format)
      githubTokenPath = hmOpts.osConfig.sops.secrets."github-access-token".path;
      tavilyKeyPath = hmOpts.osConfig.sops.secrets."tavily-api-key".path;
      cloudflareTokenPath = hmOpts.osConfig.sops.secrets."cloudflare-token".path;

      # ─── Single source of truth ───
      sshServers = {
        ssh_openwrt_old = {
          host = "192.168.5.1";
          user = "root";
          key = "id_rsa_compat";
        };
        ssh_stb = {
          host = "192.168.5.207";
          user = "klein";
        };
        ssh_mido = {
          host = "192.168.5.185";
          user = "klein";
        };
      };

      execServers = {
        github = {
          pkg = github-mcp-server-pkg;
          bin = "github-mcp-server";
          args = [ "stdio" ];
          geminiWrap = "GITHUB_PERSONAL_ACCESS_TOKEN=$(cat ${githubTokenPath})";
          env = {
            GITHUB_PERSONAL_ACCESS_TOKEN = "{file:${githubTokenPath}}";
          };
        };
        nixos = {
          pkg = pkgs.mcp-nixos;
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
          args = [ "serve" ];
        };
        tavily = {
          pkg = tavily-mcp-pkg;
          bin = "tavily-mcp";
          geminiWrap = "TAVILY_API_KEY=$(cat ${tavilyKeyPath})";
          env = {
            TAVILY_API_KEY = "{file:${tavilyKeyPath}}";
          };
        };
      };

      cloudflareCfg = {
        url = "https://mcp.cloudflare.com/mcp";
        opencodeHeaders = {
          Authorization = "Bearer {file:${cloudflareTokenPath}}";
        };
      };

      # ─── Renderers ───
      geminiSsh = lib.mapAttrs (name: cfg: makeSshMcp (cfg // { inherit homeDir; })) sshServers;

      geminiExec = lib.mapAttrs (
        name: cfg:
        if cfg ? geminiWrap then
          {
            command = "${pkgs.bash}/bin/bash";
            args = [
              "-c"
              "${cfg.geminiWrap} ${cfg.pkg}/bin/${cfg.bin} ${lib.escapeShellArgs (cfg.args or [ ])}"
            ];
          }
        else
          {
            command = "${cfg.pkg}/bin/${cfg.bin}";
            args = cfg.args or [ ];
            env = cfg.env or { };
          }
      ) execServers;

      opencodeSsh = lib.mapAttrs (name: cfg: makeOpenCodeSshMcp (cfg // { inherit homeDir; })) sshServers;

      opencodeExec = lib.mapAttrs (name: cfg: {
        type = "local";
        command = [ "${cfg.pkg}/bin/${cfg.bin}" ] ++ (cfg.args or [ ]);
        enabled = true;
        environment = cfg.env or { };
      }) execServers;
    in
    {
      home = {
        packages = [
          ssh-mcp-pkg
          codebase-memory-mcp-pkg
          google-colab-mcp-pkg
          telegram-mcp-pkg
          github-mcp-server-pkg
          tavily-mcp-pkg
          pkgs.mcp-nixos
        ];

        activation.setupMcpConfig = hmOpts.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          TOKEN_PATH="${cloudflareTokenPath}"
          BASE_CONF="$HOME/.gemini/config/mcp_config_base.json"
          FINAL_CONF="$HOME/.gemini/config/mcp_config.json"

          mkdir -p "$HOME/.gemini/config"

          if [ -f "$TOKEN_PATH" ]; then
            CF_TOKEN=$(cat "$TOKEN_PATH")
            ${pkgs.jq}/bin/jq --arg token "Bearer $CF_TOKEN" \
              '.mcpServers += {
                "cloudflare-api": {
                  "url": "${cloudflareCfg.url}",
                  "headers": {
                    "Authorization": $token
                  }
                }
              }' "$BASE_CONF" > "$FINAL_CONF"
            chmod 600 "$FINAL_CONF"
          else
            cp "$BASE_CONF" "$FINAL_CONF"
            chmod 600 "$FINAL_CONF"
          fi
        '';
      };

      home.file.".gemini/config/mcp_config_base.json".text = builtins.toJSON {
        mcpServers = geminiSsh // geminiExec;
      };

      home.file.".config/opencode/opencode.json".text = builtins.toJSON {
        "$schema" = "https://opencode.ai/config.json";
        mcp =
          opencodeSsh
          // opencodeExec
          // {
            "cloudflare-api" = {
              type = "remote";
              url = cloudflareCfg.url;
              headers = cloudflareCfg.opencodeHeaders;
            };
          };
      };
    };
}
