{
  selfLib,
  pkgs,
  ...
}:

selfLib.mkModule {
  name = "apps.social.discord";
  description = "Discord communication application";

  flatpakCfg = {
    "com.discordapp.Discord" = {
      enable = true;
      symlinks = [
        {
          host = ".config/discord";
          guest = "config/discord";
        }
      ];
      nativePkgs = pkgs.discord;
    };
  };
}
