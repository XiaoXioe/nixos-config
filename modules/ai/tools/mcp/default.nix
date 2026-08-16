{
  config,
  pkgs,
  lib,
  inputs,
  selfLib,
  ...
}:

let
  userName = config.my.user.name;
  homeDir = "/home/${userName}";

  # ── Modular Server Definitions (Auto-discovered) ─────────────────────────────
  serverModules = selfLib.scanPaths ./servers;

  # Evaluasi masing-masing server module dan saring hanya yang aktif (enable = true)
  evaluatedServers = builtins.map (
    file:
    import file {
      inherit
        config
        pkgs
        lib
        inputs
        ;
    }
  ) serverModules;

  activeServers = builtins.filter (s: s.enable or true) evaluatedServers;

  # ── Format Transformers ──────────────────────────────────────────────────────
  # Transformer ke format OpenCode ({ type = "local"; command = [...]; environment = {...}; })
  toOpencodeLocal =
    spec:
    {
      type = "local";
      command = [ spec.command ] ++ (spec.args or [ ]);
    }
    // lib.optionalAttrs (spec ? env) {
      environment = spec.env;
    };

  # Transformer ke format Gemini CLI / Antigravity ({ command = "..."; args = [...]; env = {...}; })
  toGeminiLocal =
    spec:
    {
      inherit (spec) command;
      args = spec.args or [ ];
    }
    // lib.optionalAttrs (spec ? env) {
      inherit (spec) env;
    };

  # ── MCP Configuration Aggregation ───────────────────────────────────────────
  commonServersList = builtins.filter (s: s ? commonSpec) activeServers;

  commonOpencode = builtins.listToAttrs (
    builtins.map (s: {
      inherit (s) name;
      value = toOpencodeLocal s.commonSpec;
    }) commonServersList
  );

  commonGemini = builtins.listToAttrs (
    builtins.map (s: {
      inherit (s) name;
      value = toGeminiLocal s.commonSpec;
    }) commonServersList
  );

  explicitOpencode = builtins.listToAttrs (
    builtins.map (s: {
      inherit (s) name;
      value = s.opencodeServer;
    }) (builtins.filter (s: s ? opencodeServer) activeServers)
  );

  explicitGemini = builtins.listToAttrs (
    builtins.map (s: {
      inherit (s) name;
      value = s.geminiServer;
    }) (builtins.filter (s: s ? geminiServer) activeServers)
  );

  opencodeMcpConfig = commonOpencode // explicitOpencode;

  geminiMcpConfig = {
    mcpServers = commonGemini // explicitGemini;
  };

  # ── Aggregated Properties ───────────────────────────────────────────────────
  collectedPreservationDirs = lib.concatMap (s: s.preservationUserDirectories or [ ]) activeServers;
  collectedSopsSecrets = lib.foldl' (acc: s: acc // (s.sopsSecrets or { })) { } activeServers;
  collectedSopsTemplates = lib.foldl' (acc: s: acc // (s.sopsTemplates or { })) { } activeServers;
  collectedTmpfiles = lib.concatMap (s: s.systemdTmpfilesRules or [ ]) activeServers;
  collectedHmPackages = lib.concatMap (s: s.hmPackages or [ ]) activeServers;
  collectedHmFiles = lib.foldl' (acc: s: acc // (s.hmFiles or { })) { } activeServers;
  collectedHmServices = lib.foldl' (acc: s: acc // (s.hmServices or { })) { } activeServers;
  collectedActivationHooks = lib.concatStringsSep "\n" (
    builtins.filter (h: h != "") (builtins.map (s: s.activationHook or "") activeServers)
  );

in
selfLib.mkModule {
  name = "ai.tools.mcp";
  description = "Nix-native Model Context Protocol (MCP) servers and configuration";

  preservation = {
    persist = true;
    userDirectories = collectedPreservationDirs;
  };

  nixosConfig = {
    # 1. Dekripsi rahasia menggunakan sops-nix
    sops.secrets = collectedSopsSecrets;

    # 2. Buat direktori dasar dan tmpfiles dari tiap server
    systemd.tmpfiles.rules = [
      "d ${homeDir}/.gemini 0755 ${userName} users - -"
      "d ${homeDir}/.gemini/config 0755 ${userName} users - -"
    ]
    ++ collectedTmpfiles;

    # 3. Buat berkas mcp_config.json dan templates server lainnya menggunakan sops.templates
    sops.templates = {
      "mcp_config.json" = {
        content = builtins.toJSON geminiMcpConfig;
        path = "${homeDir}/.gemini/config/mcp_config.json";
        owner = userName;
        mode = "0600";
      };
    }
    // collectedSopsTemplates;
  };

  hmConfig =
    { pkgs, lib, ... }:
    {
      home = {
        packages = collectedHmPackages;
        file = collectedHmFiles;

        # Activation murni untuk mengelola opencode.json agar tetap MUTABLE serta menjalankan hook server
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

          ${collectedActivationHooks}
        '';
      };

      systemd.user.services = collectedHmServices;
    };
}
