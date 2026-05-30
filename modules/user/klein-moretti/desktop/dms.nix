{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.my.user.dms;
in
{
  options.my.user.dms = {
    enable = lib.mkEnableOption "DankMaterialShell for Niri";
  };

  imports = [
    inputs.dms.homeModules.dank-material-shell
  ];

  config = lib.mkIf cfg.enable {
    programs.dank-material-shell = {
      # dgop.package = inputs.dgop.packages.${pkgs.stdenv.hostPlatform.system}.default;
      dgop.package = pkgs.dgop;
      enable = true;
    };

  };
}
