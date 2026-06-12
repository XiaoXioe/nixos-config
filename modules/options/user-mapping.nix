{ config, lib, ... }:
let
  # Recursively convert booleans → { enable = bool; }
  toEnable =
    value:
    if builtins.isBool value then
      { enable = value; }
    else if builtins.isAttrs value then
      builtins.mapAttrs (_: toEnable) value
    else
      value;

  # Get features for the primary user
  primaryUserFeatures = config.my.users.${config.my.user.name}.userFeatures or { };
in
{
  # Map userFeatures to the top-level 'my' namespace
  my = toEnable primaryUserFeatures;
}
