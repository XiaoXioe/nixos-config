{
  pkgs,
  inputs,
  selfLib,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  antigravity-cli = inputs.antigravity-nix.packages.${system}.google-antigravity-cli;
  antigravity-ide = inputs.antigravity-nix.packages.${system}.google-antigravity-ide;
in
selfLib.mkModule {
  name = "apps.dev.packages";
  description = "Packages for development";

  hmConfig = {
    home.packages = with pkgs; [
      nix-tree
      nix-init
      python3
      antigravity-ide
      antigravity-cli
      gemini-cli
      claude-code
      aider-chat
      cachix
      codex
    ];
  };
}
