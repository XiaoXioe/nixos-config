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
    inherit (userData) uid;
    description = userData.fullName;
    inherit (userData) extraGroups;
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = userData.openssh.authorizedKeys.keys;
    homeMode = "0700";
  };

  my = lib.recursiveUpdate (selfLib.mapFeatures userFeatures) {
    hostname = hostName;
    defaultApps =
      userData.defaultApps or {
        terminal = "foot";
        browser = "zen-beta";
        editor = "codium";
        fileManager = "dolphin";
      };
    defaultTerminal = userData.defaultApps.terminal or "foot";
    user = {
      name = userName;
      inherit fullName;
      inherit flakePath;
    };
  };

  system.stateVersion = "25.11";
}
