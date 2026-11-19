{
  pkgs,
  pkgs-unstable,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.media.gthumb";
  description = "gThumb image viewer";

  hmConfig = {
    home.packages = [
      pkgs-unstable.gthumb
      pkgs.gnome-calculator
    ];
  };
}
