{
  selfLib,
  userName,
  userFeatures,
  ...
}:
{
  home.username = userName;
  home.homeDirectory = "/home/${userName}";

  imports = [
    ../../modules/user
  ];

  # --- USER MODULES TOGGLE ---
  my.user = {
    git = if (userFeatures.git or false) then selfLib.enabled else selfLib.disabled;
    ssh = if (userFeatures.ssh or false) then selfLib.enabled else selfLib.disabled;
    nvim = if (userFeatures.nvim or false) then selfLib.enabled else selfLib.disabled;
    fish = if (userFeatures.fish or false) then selfLib.enabled else selfLib.disabled;
    tmux = if (userFeatures.tmux or false) then selfLib.enabled else selfLib.disabled;
    settings = if (userFeatures.settings or false) then selfLib.enabled else selfLib.disabled;
    startship = if (userFeatures.startship or false) then selfLib.enabled else selfLib.disabled;

    packages = if (userFeatures.packages or false) then selfLib.enabled else selfLib.disabled;
    custompkgs = if (userFeatures.custompkgs or false) then selfLib.enabled else selfLib.disabled;
    editor-file = if (userFeatures.editor_file or false) then selfLib.enabled else selfLib.disabled;
    security-tools =
      if (userFeatures.securityTools or false) then selfLib.enabled else selfLib.disabled;

    game = if (userFeatures.gaming or false) then selfLib.enabled else selfLib.disabled;
    wine = if (userFeatures.gaming or false) then selfLib.enabled else selfLib.disabled;

    brave = if (userFeatures.brave or false) then selfLib.enabled else selfLib.disabled;
    media = if (userFeatures.media or false) then selfLib.enabled else selfLib.disabled;
    music = if (userFeatures.media or false) then selfLib.enabled else selfLib.disabled;
    sosmed = if (userFeatures.sosmed or false) then selfLib.enabled else selfLib.disabled;
    office = if (userFeatures.office or false) then selfLib.enabled else selfLib.disabled;
    browser = if (userFeatures.browser or false) then selfLib.enabled else selfLib.disabled;
    firefox = if (userFeatures.firefox or false) then selfLib.enabled else selfLib.disabled;

    distrobox = if (userFeatures.distrobox or false) then selfLib.enabled else selfLib.disabled;

    dms = if (userFeatures.dms or false) then selfLib.enabled else selfLib.disabled;
    caelestia = if (userFeatures.caelestia or false) then selfLib.enabled else selfLib.disabled;
    themes = if (userFeatures.themes or false) then selfLib.enabled else selfLib.disabled;
  };

  # Toggle Modular untuk Service User
  my.user.services.rclone =
    if (userFeatures.services.rclone or false) then selfLib.enabled else selfLib.disabled;

  programs.man.generateCaches = false;
  manual = {
    manpages.enable = false;
    html.enable = false;
    json.enable = false;
  };
  home.stateVersion = "25.11";
  programs.home-manager.enable = true;
}
