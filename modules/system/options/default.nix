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
              options = {
                # Terminal & Development
                git = lib.mkEnableOption "Git configuration";
                ssh = lib.mkEnableOption "SSH configuration";
                nvim = lib.mkEnableOption "Neovim (NVF)";
                fish = lib.mkEnableOption "Fish shell";
                tmux = lib.mkEnableOption "Tmux multiplexer";
                starship = lib.mkEnableOption "Starship prompt";
                fastfetch = lib.mkEnableOption "Fastfetch system info";
                wezterm = lib.mkEnableOption "WezTerm terminal";
                nemo = lib.mkEnableOption "Nemo file manager";
                devpkgs = lib.mkEnableOption "Development packages";

                # Code editors
                editor-file = lib.mkEnableOption "Editor file associations";
                zeditor = lib.mkEnableOption "Zed editor";
                vscodium = lib.mkEnableOption "VSCodium editor";

                # Packages
                packages = lib.mkEnableOption "User packages";
                custompkgs = lib.mkEnableOption "Custom packages from private repos";
                securityTools = lib.mkEnableOption "Security/pentesting tools";

                # Media & Apps
                brave = lib.mkEnableOption "Brave browser";
                media = lib.mkEnableOption "Media players (mpv, etc.)";
                music = lib.mkEnableOption "Music stack (MPD + rmpc + cava)";
                sosmed = lib.mkEnableOption "Social media apps";
                office = lib.mkEnableOption "Office suite";
                browser = lib.mkEnableOption "Browser base packages";
                firefox = lib.mkEnableOption "Firefox browser";
                librewolf = lib.mkEnableOption "LibreWolf browser";

                # Desktop
                dms = lib.mkEnableOption "Dank Material Shell";
                caelestia = lib.mkEnableOption "Caelestia shell";
                themes = lib.mkEnableOption "GTK/Qt themes and cursors";
                settings = lib.mkEnableOption "Home file settings (symlinks)";

                # Gaming
                gaming = lib.mkEnableOption "Gaming (Steam, Lutris, etc.)";

                # Containers
                # distrobox = lib.mkEnableOption "Distrobox containers";
                # docker = lib.mkEnableOption "Docker integration";

                # Services
                services = lib.mkOption {
                  type = lib.types.submodule {
                    options.rclone = lib.mkEnableOption "Rclone mount service";
                  };
                  default = { };
                  description = "Per-user service toggles.";
                };
              };
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
