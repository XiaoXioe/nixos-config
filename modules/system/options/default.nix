# System-wide options registry: user definitions, host identity, and shared types.
{
  config,
  pkgs,
  lib,
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
          uid = lib.mkOption {
            type = lib.types.int;
            default = 1000;
            description = "The UID for the user.";
          };
          fullName = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "The full display name of the user.";
          };
          userFeatures = lib.mkOption {
            type = lib.types.submodule {
              freeformType = lib.types.attrsOf lib.types.anything;
            };
            default = { };
            description = "Per-user feature flags consumed by home-manager modules.";
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
            description = "Supplementary groups for the user.";
          };
          hashedPasswordFile = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            description = "Path to a file containing the hashed password.";
          };
          openssh = {
            authorizedKeys = {
              keys = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = "SSH public keys authorized to log in as this user.";
              };
            };
          };
        };
      }
    );
    default = { };
    description = "Attribute set of users to create.";
  };

  options.my.user = {
    name = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "The primary admin user account name.";
    };
    fullName = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "The full display name of the primary user.";
    };
    flakePath = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Absolute path to the NixOS configuration flake.";
    };
  };

  options.my.system = {
    hostname = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "The hostname of the system.";
    };
  };

  config = {
    networking.hostName = cfg.hostname;

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
