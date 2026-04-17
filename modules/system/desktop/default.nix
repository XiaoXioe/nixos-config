{
  selfLib,
  ...
}:

{
  imports = (selfLib.scanPaths ./.) ++ [
  ];
  # imports = [
  #   ./gnome.nix
  #   ./hyprland.nix
  #   ./kde.nix
  #   ./niri.nix
  # ];
}
