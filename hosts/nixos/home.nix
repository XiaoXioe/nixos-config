# Per-user home-manager configuration.
{
  userName,
  config,
  ...
}:
{
  home.username = userName;
  home.homeDirectory = "/home/${userName}";

  home.file.".cache/nix/gitv3".source =
    config.lib.file.mkOutOfStoreSymlink "/persist/home/${userName}/.cache/nix/gitv3";
  home.file.".cache/nix/tarball-cache-v2".source =
    config.lib.file.mkOutOfStoreSymlink "/persist/home/${userName}/.cache/nix/tarball-cache-v2";

  programs.man.generateCaches = false;
  manual = {
    manpages.enable = false;
    html.enable = false;
    json.enable = false;
  };
  home.stateVersion = "25.11";
  programs.home-manager.enable = true;
}
