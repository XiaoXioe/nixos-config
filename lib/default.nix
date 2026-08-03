# Custom library functions used across the configuration.
# Only helpers that provide genuine value beyond stdlib are kept here.
{
  lib,
  inputs ? null,
  ...
}:

let
  modules = import ./modules { inherit lib; };

  # Helpers to resolve secret files relative to the Flake root by name/path
  secret =
    relPath:
    if inputs != null && inputs ? self then
      inputs.self + "/secrets/${relPath}"
    else
      ../secrets + "/${relPath}";
  secretBinary = relPath: secret "binary/${relPath}";

  # Recursively maps a user features attribute set to a module enable structure.
  # For example: `{ feat = true; }` -> `{ feat = { enable = true; }; }`
  # If the key name is already "enable" (e.g. `{ feat = { enable = true; option = 1; }; }`),
  # it leaves the boolean value as-is to avoid nested wrapping (e.g. `{ enable = { enable = true; }; }`).
  mapFeatures =
    attrs:
    lib.mapAttrs (
      name: value:
      if builtins.isBool value then
        if name == "enable" then value else { enable = value; }
      else if builtins.isAttrs value then
        if value ? flatpak && value ? enable then
          let
            rest = mapFeatures (
              builtins.removeAttrs value [
                "flatpak"
                "enable"
              ]
            );
            enableVal = value.enable or true;
            flatpakVal =
              if builtins.isBool value.flatpak then { enable = value.flatpak; } else mapFeatures value.flatpak;
          in
          {
            enable = enableVal;
            flatpak = flatpakVal;
          }
          // rest
        else
          mapFeatures value
      else
        value
    ) attrs;
  secrets = import ./secrets { inherit lib secret secretBinary; };
in
{
  inherit (modules) mkModule;
  inherit
    mapFeatures
    secret
    secretBinary
    secrets
    ;

  # Helper to easily generate Home Manager out-of-store symlinks
  # Usage: selfLib.mkHmSymlinks hmOpts.config { "Documents" = "/mnt/data/Documents"; }
  mkHmSymlinks =
    hmConfig: attrs:
    lib.mapAttrs (name: path: {
      source = hmConfig.lib.file.mkOutOfStoreSymlink path;
    }) attrs;

  network = import ./network;
  shell = import ./shell;

  # Direct applied shortcuts for shell helpers
  # Usage: selfLib.mkApp pkgs "name" "script" [ pkgs.coreutils ]
  mkApp =
    pkgs: name: text: runtimeInputs:
    (import ./shell { inherit lib pkgs; }).mkApp name text runtimeInputs;
  mkScripts = pkgs: scriptsAttrSet: (import ./shell { inherit lib pkgs; }).mkScripts scriptsAttrSet;
  mkShellCompletions = pkgs: opts: (import ./shell { inherit lib pkgs; }).mkShellCompletions opts;

  # Direct shortcuts for network/VPN/WARP helpers
  warpProxyEnv = (import ./network { pkgs = null; }).warpProxyEnv;
  mkWarpWaitScript = pkgs: name: (import ./network { inherit pkgs; }).mkWarpWaitScript name;

  # Shared Firefox/Zen policy-lock helpers and AMO addon builders.
  # Call with { inherit pkgs inputs; } — kept unapplied here since lib/default.nix
  # only has `lib` in scope, not pkgs/inputs.
  browserAddons = import ./browser-addons;
  browserAddonsFor =
    {
      pkgs,
      inputs ? { },
    }:
    import ./browser-addons { inherit pkgs inputs; };

  # Auto-import all .nix files recursively (Dendritic Pattern).
  # Traverses subdirectories automatically without requiring dummy default.nix files.
  # Stops recursing if a directory contains a non-dummy default.nix module.
  scanPaths =
    path:
    let
      scanDir =
        dir:
        let
          entries = builtins.readDir dir;
          validEntries = lib.filterAttrs (
            name: type: !(lib.hasPrefix "." name) && !(lib.hasPrefix "_" name) && !(lib.hasSuffix ".bak" name)
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

  mkEqFilterString =
    filters:
    lib.concatMapStringsSep "\n                    " (
      f: "{ type = ${f.type}, freq = ${toString f.freq}, q = ${toString f.q}, gain = ${toString f.gain} }"
    ) filters;

  getVpnFiles =
    dir:
    let
      raw = if builtins.pathExists dir then builtins.readDir dir else { };
    in
    builtins.filter (name: raw.${name} == "regular" && lib.hasSuffix ".conf" name) (
      builtins.attrNames raw
    );
}
