# Per-user home-manager configuration.
# Mirrors userFeatures structure directly into my.user.* enable toggles.
{
  userName,
  userFeatures,
  ...
}:
let
  # Keys that should never be passed to home-manager modules (system-only)
  systemOnlyKeys = [
    "docker"
  ];

  # Recursively remove system-only keys from features
  recursiveRemove =
    attrs: keys:
    let
      clean = removeAttrs attrs keys;
    in
    builtins.mapAttrs (
      _: v:
      if builtins.isAttrs v then
        recursiveRemove v keys
      else
        v
    ) clean;

  # Recursively convert booleans → { enable = bool; }
  toEnable =
    value:
    if builtins.isBool value then
      { enable = value; }
    else if builtins.isAttrs value then
      builtins.mapAttrs (_: toEnable) value
    else
      value;
in
{
  home.username = userName;
  home.homeDirectory = "/home/${userName}";

  # Filter out system-level features before passing to home-manager
  my.user = toEnable (recursiveRemove userFeatures systemOnlyKeys);

  programs.man.generateCaches = false;
  manual = {
    manpages.enable = false;
    html.enable = false;
    json.enable = false;
  };
  home.stateVersion = "25.11";
  programs.home-manager.enable = true;
}
