{
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.terminal.fish";
  description = "Fish configuration";

  nixosConfig = {
    programs.fish.enable = true;
  };

  hmConfig = hmOpts: {
    imports = [
      ./settings
      ./alias
      ./function
    ];
  };
}
