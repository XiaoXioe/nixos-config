{
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.media.gthumb";
  description = "gThumb image viewer via Nix binary cache";

  hmConfig = {
    home.packages = selfLib.fetchCachePinned [
      "gthumb"
      "gnome_calculator"
    ];
  };
}
