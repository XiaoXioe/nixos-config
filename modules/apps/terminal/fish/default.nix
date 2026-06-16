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

  hmConfig = { ... }: {
    imports = [
      ./fish.nix
      ./alias.nix
      ./function.nix
    ];
  };
}
