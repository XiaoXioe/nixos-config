{
  selfLib,
  pkgs,
  ...
}:

let
  appInfo = selfLib.appVersions.zathura;

  zathuraNative = (selfLib.mkNativeApp pkgs) {
    name = "zathura";
    inherit (appInfo) version;
    src = selfLib.fetchApp pkgs "zathura";
    execPath = "usr/bin/zathura";
    binName = "zathura";
  };
in
selfLib.mkModule {
  name = "apps.office.zathura";
  description = "Zathura lightweight PDF and document reader with pure upstream binary";

  hmConfig = {
    home.packages = [ zathuraNative ];
  };
}
