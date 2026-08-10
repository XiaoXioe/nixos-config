{
  selfLib,
  flakePath,
  ...
}:

selfLib.mkModule {
  name = "apps.dev.nix.nh";
  description = "NH configuration";

  nixosConfig = {
    programs.nh = {
      enable = true;
      flake = flakePath;
      clean = {
        enable = true;
        dates = "weekly";
        extraArgs = "--keep 3";
      };
    };
  };
}
