{
  pkgs,
  inputs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.dev.nix-tools";
  description = "Nix ecosystem development, package searching, and inspection tools";

  hmConfig = hmOpts: {
    home.packages = with pkgs; [
      nix-tree
      nix-init
      cachix
    ];

    programs.nix-index = {
      enable = true;
      enableFishIntegration = true;
      package =
        inputs.nix-index-database.packages.${pkgs.stdenv.hostPlatform.system}.nix-index-with-small-db;
    };

    programs.nix-index-database.comma.enable = true;
  };
}
