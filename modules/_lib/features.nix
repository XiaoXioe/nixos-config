# Feature-toggle transformer for userFeatures attrsets.
# Recursively maps: { feat = true; } → { feat = { enable = true; }; }
{ lib }:
let
  mapFeatures =
    attrs:
    lib.mapAttrs (
      name: value:
      if builtins.isBool value then
        if name == "enable" then value else { enable = value; }
      else if builtins.isAttrs value then
        mapFeatures value
      else
        value
    ) attrs;
in
mapFeatures
