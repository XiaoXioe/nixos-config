# Per-user home-manager configuration.
{
  userName,
  selfLib ? null,
  ...
}:
{
  home.username = userName;
  home.homeDirectory = "/home/${userName}";

  programs.man.generateCaches = false;
  manual = {
    manpages.enable = false;
    html.enable = false;
    json.enable = false;
  };
  home.stateVersion = "25.11";
  programs.home-manager.enable = true;
}
