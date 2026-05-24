{
  selfLib,
  ...
}:

{
  imports = (selfLib.scanPaths ./.) ++ [
  ];
  # imports = [
  #   ./dns.nix
  #   ./openssh.nix
  #   ./vpn.nix
  # ];
}
