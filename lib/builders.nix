# Builder functions for NixOS and Home Manager configurations.
# Extracted from flake.nix to keep the entry point clean.
{
  lib,
  inputs,
  pkgs,
  hostName,
  adminUser,
  allUsers,
  baseArgs,
  homeModules,
  commonModules,
}:

let
  specialArgs = baseArgs // {
    userName = adminUser;
    fullName = allUsers.${adminUser}.fullName;
  };

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
