{
  selfLib,
  pkgs,
  ...
}:

selfLib.mkModule {
  name = "apps.custom.tradingview";
  description = "TradingView desktop charting client";

  hmConfig = {
    home.packages = [ pkgs.tradingview ];
  };
}
