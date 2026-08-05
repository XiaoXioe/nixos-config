# Feature-toggle transformer for userFeatures attrsets.
# Recursively maps: { feat = true; } → { feat = { enable = true; }; }
# Handles special-case flatpak sub-attrsets with enable + flatpak keys.
{ lib }:
let
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
in
mapFeatures
