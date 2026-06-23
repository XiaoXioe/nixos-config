{
  selfLib,
  flakePath,
  ...
}:

selfLib.mkModule {
  name = "apps.dev.nh";
  description = "NH configuration";

  hmConfig = {
    programs.nh = {
      enable = true;
      flake = flakePath;
    };
  };
}
