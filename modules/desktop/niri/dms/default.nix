{
  selfLib,
  flakePath,
  ...
}:

selfLib.mkModule {
  name = "desktop.niri.dms";
  description = "DankMaterialShell";

  hmConfig =
    { inputs, config, ... }:
    {
      imports = [
        inputs.dms.homeModules.dank-material-shell
      ];

      programs.dank-material-shell = {
        enable = true;
      };

      xdg.configFile."DankMaterialShell/settings.json".source =
        config.lib.file.mkOutOfStoreSymlink "${flakePath}/modules/desktop/niri/dms/settings.json";
      xdg.configFile."DankMaterialShell/clsettings.json".source =
        config.lib.file.mkOutOfStoreSymlink "${flakePath}/modules/desktop/niri/dms/clsettings.json";
    };
}
