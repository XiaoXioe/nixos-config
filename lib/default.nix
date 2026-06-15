# Custom library functions used across the configuration.
# Only helpers that provide genuine value beyond stdlib are kept here.
{ lib, ... }:

let
  modules = import ./modules.nix { inherit lib; };

  mapFeatures = attrs:
    lib.mapAttrs (name: value:
      if builtins.isBool value then
        if name == "enable" then value else { enable = value; }
      else if builtins.isAttrs value then
        mapFeatures value
      else
        value
    ) attrs;
in
{
  inherit (modules) mkModule;
  inherit mapFeatures;

  # Auto-import all .nix files (except default.nix) and directories
  # containing a default.nix from the given path.
  scanPaths =
    path:
    map (f: (path + "/${f}")) (
      builtins.attrNames (
        lib.filterAttrs (
          name: type:
          let
            isNixFile = lib.hasSuffix ".nix" name && name != "default.nix";
            isModuleDir = type == "directory" && builtins.pathExists (path + "/${name}/default.nix");
          in
          isNixFile || isModuleDir
        ) (builtins.readDir path)
      )
    );

  mkEqFilterString =
    filters:
    lib.concatMapStringsSep "\n                    " (
      f:
      "{ type = ${f.type}, freq = ${toString f.freq}, q = ${toString f.q}, gain = ${toString f.gain} }"
    ) filters;
}
