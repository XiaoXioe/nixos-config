{
  config,
  pkgs,
  pkgsUnstable,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.user.editor-file;
in
{
  options.my.user.editor-file = {
    enable = selfLib.mkBoolOpt false "File Editor";
  };

  config = lib.mkIf cfg.enable {

    home.packages = with pkgs; [
      pkgsUnstable.antigravity-fhs
      pkgsUnstable.gemini-cli
      nix-tree
      nix-init
      black # python formatter
      sublime4

      # inputs.nixpkgs-zed.legacyPackages.${pkgs.stdenv.hostPlatform.system}.zed-editor
      # (selfLib.pinPkg pkgs.stdenv.hostPlatform.system "26eaeac4e409d7b5a6bf6f90a2a2dc223c78d915"
      #   "zed-editor" #V 0.224.11
      # )
    ];
  };
}
