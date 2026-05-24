{
  selfLib,
  ...
}:

{
  imports = (selfLib.scanPaths ./.) ++ [
  ];
  # imports = [
  #   ./docker.nix
  #   ./packages.nix
  #   ./waydroid.nix
  # ];
}
