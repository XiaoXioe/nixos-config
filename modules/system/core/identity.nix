{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.system;
in
{
  options.my.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          uid = selfLib.mkOpt lib.types.int 1000 "The UID for the user";
          fullName = selfLib.mkOpt lib.types.str "" "The full name of the user";
          userFeatures = selfLib.mkOpt (lib.types.attrsOf lib.types.anything) { } "Optional user features mapping";
          extraGroups = selfLib.mkOpt (lib.types.listOf lib.types.str) [
            "networkmanager"
            "wheel"
            "video"
            "audio"
            "render"
            "i2c"
            "adbusers"
            "kvm"
          ] "Extra groups for the user";
          hashedPasswordFile =
            selfLib.mkOpt (lib.types.nullOr lib.types.path) null
              "Path to the hashed password file";
          openssh = {
            authorizedKeys = {
              keys = selfLib.mkOpt (lib.types.listOf lib.types.str) [ ] "The SSH authorized keys for the user";
            };
          };
        };
      }
    );
    default = { };
    description = "Attribute set of users to create";
  };

  options.my.user = {
    name = selfLib.mkOpt lib.types.str "" "The main user account name";
    fullName = selfLib.mkOpt lib.types.str "" "The full name of the user";
    flakePath = selfLib.mkOpt lib.types.str "" "The path to the nixos configuration flake";
  };

  options.my.system = {
    hostname = selfLib.mkOpt lib.types.str "" "The hostname of the system";
  };

  config = {
    networking.hostName = cfg.hostname;

    users.mutableUsers = false;
    users.users = lib.mapAttrs (name: userCfg: {
      isNormalUser = true;
      uid = userCfg.uid;
      description = userCfg.fullName;
      extraGroups = userCfg.extraGroups;
      shell = pkgs.fish;
      hashedPasswordFile = userCfg.hashedPasswordFile;
      openssh.authorizedKeys.keys = userCfg.openssh.authorizedKeys.keys;
    }) config.my.users;
  };
}
