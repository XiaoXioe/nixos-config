{
  selfLib,
  ...
}:

{
  imports = (selfLib.scanPaths ./.) ++ [
  ];
  # imports = [
  #   ./compatibility.nix
  #   ./firejail.nix
  #   ./firewall.nix
  #   ./gnupg.nix
  #   ./packages.nix
  #   ./secrets.nix
  #   ./tools.nix
  #   ./wrappers.nix
  # ];
}
