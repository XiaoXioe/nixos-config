{ pkgs, inputs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
  pkg = inputs.mcp-nixos.packages.${system}.default;
in
{
  name = "nixos";
  commonSpec = {
    command = "${pkg}/bin/mcp-nixos";
  };
}
