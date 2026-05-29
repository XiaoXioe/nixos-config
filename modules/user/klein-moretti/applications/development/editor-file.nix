{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.my.user.editor-file;
in
{
  options.my.user.editor-file = {
    enable = lib.mkEnableOption "File Editor";
  };

  config = lib.mkIf cfg.enable {

    home.packages = with pkgs; [
      antigravity-fhs
      gemini-cli
      nix-tree
      nix-init
      black # python formatter

    ];
  };
}
