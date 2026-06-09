# Per-user home-manager configuration.
# Mirrors userFeatures structure directly into my.user.* enable toggles.
{
  userName,
  userFeatures,
  ...
}:
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
in
{
  home.username = userName;
  home.homeDirectory = "/home/${userName}";

  # Filter out system-level features before passing to home-manager
  my.user = toEnable (
    removeAttrs userFeatures [
      "docker"
    ]
  );

  programs.man.generateCaches = false;
  manual = {
    manpages.enable = false;
    html.enable = false;
    json.enable = false;
  };
  home.stateVersion = "25.11";
  programs.home-manager.enable = true;
}
