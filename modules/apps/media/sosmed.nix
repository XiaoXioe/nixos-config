{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.media.sosmed";
  description = "Sosmed package for users";

  hmConfig = {
    home.packages = with pkgs; [
      ayugram-desktop
      ente-auth
      tradingview
      signal-desktop
      discord
    ];
  };
}
