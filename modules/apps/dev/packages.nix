{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.dev.packages";
  description = "Packages for development";

  hmConfig = {
    home.packages = with pkgs; [
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
