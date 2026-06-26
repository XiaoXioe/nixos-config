{
  selfLib,
  flakePath,
  ...
}:

selfLib.mkModule {
  name = "apps.dev.nh";
  description = "NH configuration";

  hmConfig = hmOpts: {
    programs.nh = {
      enable = true;
      flake = flakePath;
    };
  };
}
