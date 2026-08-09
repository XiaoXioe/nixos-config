# Builder functions for NixOS configurations.
# Extracted from flake.nix to keep the entry point clean.
{
  lib,
  pkgs,
  system,
  baseArgs,
  commonModules,
  ...
}:

let
  # NixOS configurations builder
  mkNixosConfiguration =
    hostName:
    lib.nixosSystem {
      inherit system;
      specialArgs = baseArgs // {
        inherit hostName;
      };
      modules = commonModules ++ [
        {
          nixpkgs.config.allowUnfree = true;
        }
      ];
    };
in
{
  inherit mkNixosConfiguration;
}
