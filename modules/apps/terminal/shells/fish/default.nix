{
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.terminal.shells.fish";
  description = "Fish configuration";

  preservation = {
    userDirectories = [ ".cache/fish" ];
  };

  nixosConfig = {
    programs.fish.enable = true;
  };

  hmConfig = hmOpts: {
    imports = selfLib.scanPaths ./.;
  };
}
