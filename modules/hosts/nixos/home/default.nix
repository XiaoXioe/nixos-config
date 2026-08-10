# Per-user home-manager configuration.
{
  userName,
  ...
}:
{
  home = {
    username = userName;
    homeDirectory = "/home/${userName}";
    stateVersion = "25.11";
  };

  programs.man.generateCaches = false;
  manual = {
    manpages.enable = false;
    html.enable = false;
    json.enable = false;
  };
  programs.home-manager.enable = true;
}
