{
  selfLib,
  flakePath,
  ...
}:

selfLib.mkModule {
  name = "desktop.niri.dms";
  description = "DankMaterialShell";

  preservation = {
    userDirectories = [ ".cache/DankMaterialShell" ];
  };

  hmConfig =
    { inputs, config, ... }:
    {
      imports = [
        inputs.dms.homeModules.dank-material-shell
      ];

      programs.dank-material-shell = {
        enable = true;
      };

      xdg.configFile = selfLib.mkHmSymlinks config {
        "DankMaterialShell/settings.json" = "${flakePath}/modules/desktop/niri/dms/settings.json";
        "DankMaterialShell/clsettings.json" = "${flakePath}/modules/desktop/niri/dms/clsettings.json";
      };
    };
}
