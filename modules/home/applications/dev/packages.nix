{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  cfg = config.my.user.apps.dev.packages;
in
{
  options.my.user.apps.dev.packages = {
    enable = lib.mkEnableOption "Packages for development";
  };
  config = lib.mkIf cfg.enable {

    home.packages =
      with pkgs;
      [
        nix-tree
        nix-init
        python3
        antigravity-fhs
        gemini-cli
        claude-code
        aider-chat
        cachix
        codex

      ];

  };
}
