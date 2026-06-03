{
  config,
  pkgs,
  lib,
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

    home.packages = with pkgs; [
      nix-tree
      nix-init

      ## Formatters
      black # Untuk Python
      shfmt # Untuk Bash
      nixfmt # Untuk Nix

      ## Linters
      ruff # Untuk Python
      shellcheck # Untuk Bash
      nixd
    ];
  };
}
