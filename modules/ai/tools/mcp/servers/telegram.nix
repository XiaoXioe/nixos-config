{ pkgs, inputs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
  pkg = inputs.nix-mcp.packages.${system}.telegram-mcp;
in
{
  name = "telegram-mcp";
  commonSpec = {
    command = "${pkg}/bin/telegram-mcp";
  };

  preservationUserDirectories = [
    ".telegram-mcp"
  ];
}
