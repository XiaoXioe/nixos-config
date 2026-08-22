{ pkgs, lib }:

let
  mkUnwrapped = import ./unwrapped.nix { inherit pkgs lib; };
  mkWrapped = import ./wrapper.nix { inherit pkgs lib; };
in
{
  inherit mkUnwrapped mkWrapped;

  mkNativeApp =
    args@{
      pname ? args.name,
      name ? pname,
      ...
    }:
    let
      unwrapped = mkUnwrapped (args // { inherit pname name; });
      wrapped = mkWrapped (args // { inherit pname name unwrapped; });
    in
    wrapped;
}
