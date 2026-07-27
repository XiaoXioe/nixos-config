{
  userName,
  hostName,
  fullName,
  flakePath,
  userFeatures,
  userData,
  selfLib,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration
  ];

  # Single user definition
  users.mutableUsers = false;
  users.users.${userName} = {
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
