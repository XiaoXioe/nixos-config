{
  selfLib,
  ...
}:

{
  imports = (selfLib.scanPaths ./.) ++ [
  ];
  # imports = [
  #   ./daily.nix
  #   ./kernel.nix
  #   ./retro-gaming.nix
  # ];
}
