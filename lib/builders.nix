# Builder functions for NixOS and Home Manager configurations.
# Extracted from flake.nix to keep the entry point clean.
{
  lib,
  inputs,
  pkgs,
  hostName,
  adminUser,
  baseArgs,
  homeModules,
  commonModules,
  ...
}:

let
  specialArgs = baseArgs;

  # Standalone Home Manager configuration (single user)
  mkHomeConfigurations = {
    "${adminUser}@${hostName}" = inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = baseArgs;
      modules = homeModules;
    };
  };

  # NixOS configurations (one per host)
  mkNixosConfigurations = {
    ${hostName} = lib.nixosSystem {
      inherit pkgs;
      inherit specialArgs;
      modules = commonModules ++ [
        { boot.kernelPackages = pkgs.linuxPackages_zen; }
      ];
    };
  };
in
{
  inherit
    mkHomeConfigurations
    mkNixosConfigurations
    hostName
    adminUser
    ;
}
