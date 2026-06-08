{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  cfg = config.my.user.devpkgs;
in
{
  options.my.user.devpkgs = {
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
      ]
      ++ [
        inputs.codex-cli-nix.packages.${pkgs.system}.default
      ];
  };
}
