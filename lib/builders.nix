# Builder functions for NixOS configurations.
# Extracted from flake.nix to keep the entry point clean.
{
  lib,
  pkgs,
  baseArgs,
  commonModules,
  ...
}:

let
  # NixOS configurations builder
  mkNixosConfiguration =
    hostName:
    lib.nixosSystem {
      inherit pkgs;
      specialArgs = baseArgs // {
        inherit hostName;
      };
      modules = commonModules;
    };
in
{
  inherit mkNixosConfiguration;
}
