# Custom library functions used across the configuration.
# Only helpers that provide genuine value beyond stdlib are kept here.
{ lib, ... }:

{
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

  # Apply a function to every user and merge the results.
  # Useful for generating per-user systemd units, secrets, etc.
  forAllUsers =
    users: func:
    lib.mkMerge (lib.mapAttrsToList (userName: userConfig: func userName userConfig) users);
}
