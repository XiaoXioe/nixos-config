{
  selfLib,
  flakePath,
  ...
}:

selfLib.mkModule {
  name = "apps.dev.nh";
  description = "NH configuration";

  nixosConfig = {
    programs.nh = {
      enable = true;
      clean = {
        enable = true;
        dates = "weekly";
        extraArgs = "--keep 3";
      };
    };
  };

  hmConfig = hmOpts: {
    programs.nh = {
      enable = true;
      flake = flakePath;
    };
  };
}
