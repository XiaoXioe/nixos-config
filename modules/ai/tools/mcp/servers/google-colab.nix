{ pkgs, inputs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
  pkg = inputs.nix-mcp.packages.${system}.google-colab-mcp;
in
{
  name = "google-colab-mcp";
  commonSpec = {
    command = "${pkg}/bin/colab-mcp";
  };

  preservationUserDirectories = [
    {
      directory = ".mcp-colab";
      mode = "0700";
    }
  ];
}
