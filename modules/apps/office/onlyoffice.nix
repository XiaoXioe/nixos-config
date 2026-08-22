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
  };
in
selfLib.mkModule {
  name = "apps.office.onlyoffice";
  description = "OnlyOffice Desktop Editors office suite";

  hmConfig = {
    home.packages = [ onlyofficeNative ];
  };
}
