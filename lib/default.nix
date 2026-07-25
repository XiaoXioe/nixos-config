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
  secretBinary = name: secret "binary/${name}";

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
          if rest == { } then
            {
              enable = enableVal;
              flatpak = flatpakVal;
            }
          else
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
in
{
  inherit (modules) mkModule;
  inherit mapFeatures secret secretBinary;

  # Shared Firefox/Zen policy-lock helpers and AMO addon builders.
  # Call with { inherit pkgs inputs; } — kept unapplied here since lib/default.nix
  # only has `lib` in scope, not pkgs/inputs.
  browserAddons = import ./browser-addons.nix;

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
            isModuleDir = type == "directory";
          in
          isNixFile || isModuleDir
        ) (builtins.readDir path)
      )
    );

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
