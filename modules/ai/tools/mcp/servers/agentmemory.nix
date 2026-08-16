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
  pkg = inputs.nix-mcp.packages.${system}.agentmemory;
in
{
  name = "agentmemory";

  # Status toggle: dinonaktifkan (dibiarkan utuh tetapi nonaktif)
  enable = false;

  commonSpec = {
    command = "${pkg}/bin/agentmemory-mcp";
    env = {
      AGENTMEMORY_URL = "http://127.0.0.1:3111";
      AGENTMEMORY_DATA_DIR = "${homeDir}/.agentmemory";
      AGENTMEMORY_TOOLS = "all";
    };
  };

  preservationUserDirectories = [
    ".agentmemory"
  ];

  systemdTmpfilesRules = [
    "d ${homeDir}/.agentmemory 0755 ${userName} users - -"
  ];

  hmServices = {
    agentmemory = {
      Unit = {
        Description = "AgentMemory Persistent Memory Engine & Web Viewer";
        After = [ "network.target" ];
      };
      Service = {
        WorkingDirectory = "%h/.agentmemory";
        ExecStart = "${pkg}/bin/agentmemory";
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
