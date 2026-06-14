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
  userData = import ./users.nix;
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
  };

  system.stateVersion = "25.11";
}
