{
  pkgs,
  selfLib,
  ...
}:

let
  appInfo = selfLib.appVersions.gthumb;

  gthumbNative = (selfLib.mkNativeApp pkgs) {
    name = "gthumb";
    inherit (appInfo) version;
    src = selfLib.fetchApp pkgs "gthumb";
    execPath = "usr/bin/gthumb";
    binName = "gthumb";
  };
in
selfLib.mkModule {
  name = "apps.media.gthumb";
  description = "gThumb image viewer with pure upstream binary";

  hmConfig = {
    home.packages = [ gthumbNative ];
  };
}
