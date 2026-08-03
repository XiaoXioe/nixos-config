{
  selfLib,
  pkgs,
  ...
}:

selfLib.mkModule {
  name = "apps.office.zathura";
  description = "Zathura lightweight PDF and document reader";

  flatpakCfg = {
    "org.pwmt.zathura" = {
      enable = true;
      symlinks = [
        {
          host = ".local/share/zathura";
          guest = "data/zathura";
        }
      ];
      nativePkgs = pkgs.zathura;
    };
  };
}
