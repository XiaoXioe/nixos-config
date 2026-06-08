# Per-user home-manager configuration.
# Maps userFeatures flags from lib/users.nix to module enable toggles.
{
  lib,
  userName,
  userFeatures,
  ...
}:
let
  # Keys handled separately (name differs from option, or no matching option).
  excludedKeys = [
    "gaming" # → mapped to my.user.game + my.user.wine
    "securityTools" # → mapped to my.user.security-tools
  ];

  # Standard toggles: feature flag name matches module option name exactly.
  # Filter to only boolean flags (excludes nested attrs like `services`),
  # then remove keys that are handled by renamedToggles below.
  standardToggles = lib.mapAttrs (_name: value: { enable = value; }) (
    lib.filterAttrs (name: v: builtins.isBool v && !(builtins.elem name excludedKeys)) userFeatures
  );

  # Features where the flag name differs from the module option name.
  renamedToggles = {
    security-tools = {
      enable = userFeatures.securityTools or false;
    };
    game = {
      enable = userFeatures.gaming or false;
    };
    wine = {
      enable = userFeatures.gaming or false;
    };
  };

in
{
  home.username = userName;
  home.homeDirectory = "/home/${userName}";

  # --- User Module Toggles ---
  my.user =
    standardToggles
    // renamedToggles
    // {
      services.rclone.enable = userFeatures.services.rclone or false;
    };

  programs.man.generateCaches = false;
  manual = {
    manpages.enable = false;
    html.enable = false;
    json.enable = false;
  };
  home.stateVersion = "25.11";
  programs.home-manager.enable = true;
}
