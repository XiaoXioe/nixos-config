{
  config,
  lib,
  selfLib,
  pkgs,
  ...
}:

selfLib.mkModule {
  name = "virtualisation.podman";
  description = "Podman OCI container engine configuration";

  nixosConfig = import ./storage.nix { inherit config lib pkgs; };
}
