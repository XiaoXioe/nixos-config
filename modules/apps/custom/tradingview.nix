{
  selfLib,
  pkgs,
  ...
}:

let
  appInfo = selfLib.appVersions.tradingview;

  tradingviewNative = (selfLib.mkNativeApp pkgs) {
    name = "tradingview";
    inherit (appInfo) version;
    src = selfLib.fetchApp pkgs "tradingview";
    execPath = "tradingview";
    binName = "tradingview";
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
  name = "apps.custom.tradingview";
  description = "TradingView desktop charting client";

  hmConfig = {
    home.packages = [ tradingviewNative ];
  };
}
