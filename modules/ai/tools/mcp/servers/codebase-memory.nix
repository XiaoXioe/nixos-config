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
  pkg = inputs.nix-mcp.packages.${system}.codebase-memory-mcp;
in
{
  name = "codebase-memory-mcp";
  commonSpec = {
    command = "${pkg}/bin/codebase-memory-mcp";
    env = {
      CBM_CACHE_DIR = "${homeDir}/.agents/codebase_memory";
    };
  };

  preservationUserDirectories = [
    ".agents"
  ];
}
