{
  userName,
  hostName,
  fullName,
  flakePath,
  userFeatures,
  selfLib,
  lib,
  pkgs,
  ...
}:
let
  userData = import ../../lib/users.nix;
in
{
  imports = [
    ./hardware-configuration.nix
  ];

  # Single user definition
  users.mutableUsers = false;
  users.users.klein-moretti = {
    isNormalUser = true;
    uid = userData.uid;
    description = userData.fullName;
    extraGroups = userData.extraGroups;
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = userData.openssh.authorizedKeys.keys;
  };

  my = lib.recursiveUpdate (selfLib.mapFeatures userFeatures) {
    hostname = hostName;
    user = {
      name = userName;
      fullName = fullName;
      flakePath = flakePath;
    };

    # Force enable host-specific baseline options
    services = {
      core.enable = true;
      networking.openssh.enable = true;
    };

    security = {
      wrappers.enable = true;
      secrets.enable = true;
      packages.enable = true;
      hardening.enable = true;
      networking.enable = true;
    };

    hardware = {
      auto-mount.enable = true;
      preservation.enable = true;
    };
  };

  system.stateVersion = "25.11";
}
