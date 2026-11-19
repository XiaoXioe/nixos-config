{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.social.signal";
  description = "Signal Messenger desktop application";

  hmConfig = {
    home.packages = [ pkgs.signal-desktop ];
  };
}
