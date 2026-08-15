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

  hmConfig = {
    imports = selfLib.scanPaths ./.;
  };
}
