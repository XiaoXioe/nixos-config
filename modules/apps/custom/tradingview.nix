{
  selfLib,
  pkgs,
  ...
}:

selfLib.mkModule {
  name = "apps.custom.tradingview";
  description = "TradingView desktop charting client";

  flatpakCfg = {
    "com.tradingview.tradingview" = {
      enable = true;
      symlinks = [
        {
          host = ".config/TradingView";
          guest = "config/TradingView";
        }
      ];
      nativePkgs = pkgs.tradingview;
    };
  };
}
