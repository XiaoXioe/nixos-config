{ lib }:

let
  identity = import ./identity.nix;
  appsFeatures = import ./features/apps.nix;
  systemFeatures = import ./features/system.nix;
in
identity
// {
  userFeatures = lib.recursiveUpdate appsFeatures.userFeatures systemFeatures.userFeatures;
}
