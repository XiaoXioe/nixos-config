{
  selfLib,
  ...
}:

{
  imports = (selfLib.scanPaths ./.) ++ [
  ];
  # imports = [
  #   ./bootloader.nix
  #   ./environment.nix
  #   ./fonts.nix
  #   ./graphics.nix
  #   ./identity.nix
  #   ./locale.nix
  #   ./nix-settings.nix
  #   ./optimizations.nix
  #   ./packages.nix
  # ];
}
