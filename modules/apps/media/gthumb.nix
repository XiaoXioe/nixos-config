{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.media.gthumb";
  description = "gThumb image viewer";

  flatpakCfg = {
    "org.gnome.gThumb" = {
      enable = true;
      flatpak = false;
      nativePkgs = pkgs.gthumb;
    };
  };
}
