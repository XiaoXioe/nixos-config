{
  pkgs,
  inputs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "desktop.dms";
  description = "DankMaterialShell for Niri";

  hmConfig = {
    imports = [ inputs.dms.homeModules.dank-material-shell ];
    programs.dank-material-shell = {
      dgop.package = pkgs.dgop;
      enable = true;
    };
  };
}
