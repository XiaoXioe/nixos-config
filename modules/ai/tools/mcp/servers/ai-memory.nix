{
  config,
  pkgs,
  inputs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  userName = config.my.user.name;
  homeDir = "/home/${userName}";
  mcpPkg = inputs.nix-mcp.packages.${system}.ai-memory;
  secretsFile = ../../secrets.yaml;
in
{
  name = "ai-memory";

  geminiServer = {
    serverUrl = "http://127.0.0.1:49374/mcp";
    httpUrl = "http://127.0.0.1:49374/mcp";
    timeout = 5000;
  };

  opencodeServer = {
    type = "remote";
    url = "http://127.0.0.1:49374/mcp";
    enabled = true;
  };

  sopsSecrets = {
    "nine-router-api-key" = {
      sopsFile = secretsFile;
      owner = userName;
      mode = "0400";
    };
  };

  sopsTemplates = {
    "ai-memory.env" = {
      content = ''
        AI_MEMORY_LLM_PROVIDER=openai-compat
        AI_MEMORY_LLM_BASE_URL=http://192.168.5.207:20128/v1
        AI_MEMORY_LLM_MODEL=ag/gemini-3.7-flash-high
        LLM_API_KEY=${config.sops.placeholder."nine-router-api-key"}
        AI_MEMORY_LLM_COMPAT_STRICT=false
        AI_MEMORY_CONSOLIDATE_ON_SESSION_END=true

        AI_MEMORY_EMBEDDING_PROVIDER=openai-compat
        AI_MEMORY_EMBEDDING_BASE_URL=http://192.168.5.207:20128/v1
        AI_MEMORY_EMBEDDING_MODEL=gemini/gemini-embedding-2-preview
        AI_MEMORY_EMBEDDING_DIM=3072
      '';
      path = "${homeDir}/.config/ai-memory/env";
      owner = userName;
      mode = "0600";
    };
  };

  systemdTmpfilesRules = [
    "d ${homeDir}/.ai-memory 0755 ${userName} users - -"
    "d ${homeDir}/.local/share/ai-memory 0755 ${userName} users - -"
    "d ${homeDir}/.config/ai-memory 0755 ${userName} users - -"
  ];

  preservationUserDirectories = [
    ".local/share/ai-memory"
  ];

  hmPackages = [
    mcpPkg
  ];

  hmFiles = {
    ".ai-memory.toml".text = ''
      [briefing]
      inject_on_session_start = true
      max_chars = 10000

      [recall]
      default_global = true
    '';
  };

  hmServices = {
    ai-memory = {
      Unit = {
        Description = "ai-memory Persistent Memory Engine & Web Viewer";
        After = [ "network.target" ];
      };
      Service = {
        WorkingDirectory = "%h/.local/share/ai-memory";
        EnvironmentFile = [ "%h/.config/ai-memory/env" ];
        ExecStart = "${mcpPkg}/bin/ai-memory --data-dir %h/.local/share/ai-memory --config %h/.config/ai-memory/config.toml serve --bind 127.0.0.1:49374 --transport http --enable-web";
        Restart = "on-failure";
        RestartSec = 5;
        StandardOutput = "null";
        StandardError = "null";
        Environment = [
          "HOME=%h"
          "PATH=/etc/profiles/per-user/%u/bin:/run/current-system/sw/bin"
        ];
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };

  activationHook = ''
    # Auto-configure ai-memory lifecycle hooks & managed skills for supported agents
    if [ -x "${mcpPkg}/bin/ai-memory" ]; then
      if [ -d "$HOME/.local/share/ai-memory/hooks" ]; then
        ${pkgs.coreutils}/bin/chmod -R u+w "$HOME/.local/share/ai-memory/hooks" 2>/dev/null || true
      fi
      ${mcpPkg}/bin/ai-memory install-hooks --agent opencode --apply 2>/dev/null || true
      ${mcpPkg}/bin/ai-memory install-hooks --agent antigravity-cli --apply 2>/dev/null || true
      ${mcpPkg}/bin/ai-memory install-skills --scope global --agent both 2>/dev/null || true
      ${mcpPkg}/bin/ai-memory install-skills --target-dir "$HOME/.gemini/antigravity-cli/skills" 2>/dev/null || true
    fi
  '';
}
