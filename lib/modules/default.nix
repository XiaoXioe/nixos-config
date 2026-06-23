{ lib, ... }:

{
  mkModule = import ./mkModule.nix { inherit lib; };
  mkApp = import ./mkApp.nix { inherit lib; };
}
