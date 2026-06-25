{ lib, ... }:

{
  mkModule = import ./mkModule.nix { inherit lib; };
}
