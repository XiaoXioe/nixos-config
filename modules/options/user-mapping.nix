{
  userName,
  allUsers,
  ...
}:
let
  # Recursively convert booleans → { enable = bool; }
  # If the key is already 'enable', we keep the boolean value as is.
  toEnable =
    name: value:
    if name == "enable" && builtins.isBool value then
      value
    else if builtins.isBool value then
      { enable = value; }
    else if builtins.isAttrs value then
      builtins.mapAttrs toEnable value
    else
      value;

  # Get features for the primary user
  primaryUserFeatures = allUsers.${userName}.userFeatures or { };
in
{
  # Map userFeatures to the top-level 'my' namespace
  my = builtins.mapAttrs toEnable primaryUserFeatures;
}
