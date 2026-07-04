# Builder functions for NixOS configurations.
# Extracted from flake.nix to keep the entry point clean.
{
  lib,
  pkgs,
  hostName,
  baseArgs,
  commonModules,
  ...
}:

let
  specialArgs = baseArgs;

  # NixOS configurations (one per host)
  mkNixosConfigurations = {
    ${hostName} = lib.nixosSystem {
      inherit pkgs;
      inherit specialArgs;
      modules = commonModules;
    };
  };
in
{
  inherit
    mkNixosConfigurations
    hostName
    ;
}
