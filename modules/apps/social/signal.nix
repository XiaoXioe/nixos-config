{
  selfLib,
  pkgs,
  ...
}:

selfLib.mkModule {
  name = "apps.social.signal";
  description = "Signal Messenger application";

  flatpakCfg = {
    "org.signal.Signal" = {
      enable = true;
      symlinks = [
        {
          host = ".config/Signal";
          guest = "config/Signal";
        }
      ];
      nativePkgs = pkgs.signal-desktop;
    };
  };
}
