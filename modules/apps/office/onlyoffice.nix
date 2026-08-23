{
  selfLib,
  pkgs,
  ...
}:

let
  appInfo = selfLib.appVersions.onlyoffice;

  onlyofficeNative = (selfLib.mkNativeApp pkgs) {
    name = "onlyoffice-desktopeditors";
    inherit (appInfo) version;
    src = selfLib.fetchApp pkgs "onlyoffice";
    execPath = "opt/onlyoffice/desktopeditors/DesktopEditors";
    binName = "desktopeditors";
    extraEnv = {
      QT_PLUGIN_PATH = "${onlyofficeNative.unwrapped}/opt/onlyoffice-desktopeditors/opt/onlyoffice/desktopeditors";
    };
    extraWrapperArgs = [
      "--prefix LD_LIBRARY_PATH : ${onlyofficeNative.unwrapped}/opt/onlyoffice-desktopeditors/opt/onlyoffice/desktopeditors"
      "--prefix NIX_LD_LIBRARY_PATH : ${onlyofficeNative.unwrapped}/opt/onlyoffice-desktopeditors/opt/onlyoffice/desktopeditors"
    ];
  };
in
selfLib.mkModule {
  name = "apps.office.onlyoffice";
  description = "OnlyOffice Desktop Editors office suite";

  hmConfig = {
    home.packages = [ onlyofficeNative ];
  };
}
