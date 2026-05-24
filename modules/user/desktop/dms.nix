{
  config,
  lib,
  pkgs,
  selfLib,
  inputs,
  ...
}:
let
  cfg = config.my.user.dms;
in
{
  options.my.user.dms = {
    enable = selfLib.mkBoolOpt false "DankMaterialShell untuk Niri";
  };

  imports = [
    inputs.dms.homeModules.dank-material-shell
  ];

  config = lib.mkIf cfg.enable {
    programs.dank-material-shell = {
      dgop.package = inputs.dgop.packages.${pkgs.stdenv.hostPlatform.system}.default;
      # dgop.package = pkgs.dgop;
      enable = true;
    };

  };
}
