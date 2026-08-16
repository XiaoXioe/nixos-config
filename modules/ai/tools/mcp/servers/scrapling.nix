{
  config,
  pkgs,
  inputs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  userName = config.my.user.name;
  pkg = inputs.nix-mcp.packages.${system}.scrapling;
in
{
  name = "scrapling";
  commonSpec = {
    command = "${pkg}/bin/scrapling";
    args = [ "mcp" ];
    env = {
      SCRAPLING_EXECUTABLE_PATH = "/etc/profiles/per-user/${userName}/bin/chromium";
    };
  };
}
