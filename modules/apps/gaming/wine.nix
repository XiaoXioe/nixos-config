{
  pkgs,
  selfLib,
  ...
}:

let
  appInfo = selfLib.appVersions.wine;

  wineNative = (selfLib.mkNativeApp pkgs) {
    name = "wine";
    inherit (appInfo) version;
    src = selfLib.fetchApp pkgs "wine";
    execPath = "wine-${appInfo.version}-staging-amd64-wow64/bin/wine";
    binName = "wine";
    isDesktop = false;
  };
in
selfLib.mkModule {
  name = "apps.gaming.wine";
  description = "Wine and compatibility layer with pure upstream binary";

  hmConfig =
    hmOpts:
    let
      dataPath = hmOpts.osConfig.my.dataPath;
    in
    {
      home = {
        packages = [
          wineNative
        ];

        sessionVariables = {
          WINEDLLOVERRIDES = "winemenubuilder.exe=d";
          WINEPREFIX = "${dataPath}/wine-data";
          WINEARCH = "win64";
        };
      };
    };
}
