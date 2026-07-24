{
  selfLib,
  pkgs,
  ...
}:

selfLib.mkModule {
  name = "security.ente-auth";
  description = "Ente Auth 2FA desktop application";

  flatpakCfg = {
    "io.ente.auth" = {
      enable = true;
      symlinks = [
        {
          host = ".local/share/io.ente.auth";
          guest = "data/enteauth";
        }
      ];
      nativePkgs = pkgs.ente-auth;
    };
  };
}
