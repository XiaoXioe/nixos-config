# Builder functions for NixOS and Home Manager configurations.
# Extracted from flake.nix to keep the entry point clean.
{
  lib,
  inputs,
  pkgs,
  hostName,
  adminUser,
  allUsers,
  selfLib,
  baseArgs,
  commonSpecialArgs,
  homeModules,
  commonModules,
}:

let
  # Standalone Home Manager configurations (one per user)
  mkHomeConfigurations = lib.mapAttrs' (name: user: {
    name = "${name}@${hostName}";
    value = inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;

      extraSpecialArgs = baseArgs // {
        userName = name;
        fullName = user.fullName;
        userFeatures = user.userFeatures or { };
      };

      modules = homeModules;
    };
  }) allUsers;

  # NixOS configurations (one per host)
  mkNixosConfigurations = {
    ${hostName} = lib.nixosSystem {
      inherit pkgs;
      specialArgs = commonSpecialArgs;
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
