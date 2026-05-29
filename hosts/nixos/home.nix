# Per-user home-manager configuration.
# Maps userFeatures flags from lib/users.nix to module enable toggles.
{
  userName,
  userFeatures,
  ...
}:
let
  # Helper: convert a userFeatures flag to { enable = bool; }
  feat = key: { enable = userFeatures.${key} or false; };

  # Some module names differ from the feature flag name.
  # This table maps: moduleOptionName → featureFlagName
  featureMap = {
    # Terminal & Development
    git = "git";
    ssh = "ssh";
    nvim = "nvim";
    fish = "fish";
    tmux = "tmux";
    wezterm = "wezterm";
    settings = "settings";
    startship = "startship";
    fastfetch = "fastfetch";

    # Packages
    packages = "packages";
    custompkgs = "custompkgs";
    zeditor = "zeditor";

    # Media & Apps
    brave = "brave";
    media = "media";
    music = "media";        # music follows the media flag
    sosmed = "sosmed";
    office = "office";
    browser = "browser";
    firefox = "firefox";
    librewolf = "librewolf";

    # Desktop
    dms = "dms";
    caelestia = "caelestia";
    themes = "themes";
  };

  # Generate the standard toggles from the feature map
  standardToggles = builtins.mapAttrs (_name: flagKey: feat flagKey) featureMap;

  # Toggles that need special mapping (feature name ≠ option name)
  specialToggles = {
    editor-file = feat "editor_file";
    security-tools = feat "securityTools";
    game = feat "gaming";
    wine = feat "gaming";
  };

in
{
  home.username = userName;
  home.homeDirectory = "/home/${userName}";


  # --- User Module Toggles ---
  my.user = standardToggles // specialToggles // {
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
