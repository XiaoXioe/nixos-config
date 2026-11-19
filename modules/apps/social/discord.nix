{
  selfLib,
  pkgs,
  ...
}:

selfLib.mkModule {
  name = "apps.social.discord";
  description = "Discord communication desktop application";

  hmConfig = {
    home.packages = [ pkgs.discord ];
  };
}
