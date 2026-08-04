# Filesystem helpers: Dendritic auto-import traverser + VPN conf scanner.
{ lib }:
{
  # Auto-import all .nix files recursively (Dendritic Pattern).
  # Traverses subdirectories automatically without requiring dummy default.nix files.
  # Stops recursing if a directory contains a non-dummy default.nix module.
  # Usage: imports = selfLib.scanPaths ./.;
  scanPaths =
    path:
    let
      scanDir =
        dir:
        let
          entries = builtins.readDir dir;
          validEntries = lib.filterAttrs (
            name: _: !(lib.hasPrefix "." name) && !(lib.hasPrefix "_" name) && !(lib.hasSuffix ".bak" name)
          ) entries;
          hasDefaultNix = (entries ? "default.nix") && dir != path;
        in
        if hasDefaultNix then
          [ (dir + "/default.nix") ]
        else
          lib.concatLists (
            lib.mapAttrsToList (
              name: type:
              let
                subPath = dir + "/${name}";
              in
              if type == "directory" then
                scanDir subPath
              else if type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix" then
                [ subPath ]
              else
                [ ]
            ) validEntries
          );
    in
    scanDir path;

  # Return a list of WireGuard .conf filenames found in the given directory.
  # Usage: vpnFiles = selfLib.getVpnFiles /etc/nixos/vpn;
  getVpnFiles =
    dir:
    let
      raw = if builtins.pathExists dir then builtins.readDir dir else { };
    in
    builtins.filter (name: raw.${name} == "regular" && lib.hasSuffix ".conf" name) (
      builtins.attrNames raw
    );
}
