{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.gaming.wine";
  description = "Wine and compatibility layer with WoW64 staging support";

  hmConfig =
    hmOpts:
    let
      dataPath = hmOpts.osConfig.my.dataPath;
    in
    {
      home = {
        packages = [
          pkgs.wineWow64Packages.staging
        ];

        sessionVariables = {
          WINEDLLOVERRIDES = "winemenubuilder.exe=d";
          WINEPREFIX = "${dataPath}/wine-data";
          WINEARCH = "win64";
        };
      };
    };
}
