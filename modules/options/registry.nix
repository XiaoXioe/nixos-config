# System-wide options registry: user definitions, host identity, and shared types.
{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.my.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          uid = lib.mkOption {
            type = lib.types.int;
            default = 1000;
          };
          fullName = lib.mkOption {
            type = lib.types.str;
            default = "";
          };
          userFeatures = lib.mkOption {
            type = lib.types.submodule {
              freeformType = lib.types.attrsOf lib.types.anything;
            };
            default = { };
          };
          extraGroups = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [
              "networkmanager"
              "wheel"
              "video"
              "audio"
              "render"
              "i2c"
              "adbusers"
              "kvm"
            ];
          };
          hashedPasswordFile = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
          };
          openssh.authorizedKeys.keys = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
          };
        };
      }
    );
    default = { };
  };

  options.my.user = {
    name = lib.mkOption { type = lib.types.str; default = ""; };
    fullName = lib.mkOption { type = lib.types.str; default = ""; };
    flakePath = lib.mkOption { type = lib.types.str; default = ""; };
  };

  options.my.hostname = lib.mkOption {
    type = lib.types.str;
    default = "";
  };

  config = {
    networking.hostName = config.my.hostname;
    users.mutableUsers = false;
    users.users = lib.mapAttrs (_name: userCfg: {
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
