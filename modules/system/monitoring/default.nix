{
  selfLib,
  ...
}:

{
  imports = (selfLib.scanPaths ./.) ++ [
  ];
  # imports = [
  #   ./ananicy.nix
  #   ./snapper.nix
  #   ./ssd-tbw.nix
  #   ./system-service.nix
  #   ./tmpfiles.nix
  # ];
}
