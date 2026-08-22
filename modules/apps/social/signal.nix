{
  selfLib,
  pkgs,
  ...
}:

let
  appInfo = selfLib.appVersions.signal;

  signalNative = (selfLib.mkNativeApp pkgs) {
    name = "signal-desktop";
    inherit (appInfo) version;
    src = selfLib.fetchApp pkgs "signal";
    execPath = "opt/Signal/signal-desktop";
    binName = "signal-desktop";
    extraArgs = [
      "--enable-features=UseOzonePlatform"
      "--ozone-platform=wayland"
    ];
    extraEnv = {
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
    };
  };
in
selfLib.mkModule {
  name = "apps.social.signal";
  description = "Signal Messenger desktop application";

  hmConfig = {
    home.packages = [ signalNative ];
  };
}
