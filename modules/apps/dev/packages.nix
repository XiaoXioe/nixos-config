{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.dev.packages";
  description = "Packages for development";

  hmConfig = {
    home.packages = with pkgs; [
      nodejs_22
      uv
      nix-tree
      nix-init
      python3
      cachix
    ];
  };
}
