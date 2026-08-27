{
  lib,
  selfLib,
  ...
}:

let
  userSymlinkDirs = [
    "Documents"
    "Downloads"
    "Pictures"
    "Videos"
    "Music"
    "PersistentData"
  ];
  userDirs = userSymlinkDirs ++ [ "podman" ];
in
selfLib.mkModule {
  name = "settings.files";
  description = "Home file settings";

  preservation = {
    persist = true;
    directories = [
      "/var/lib/AccountsService"
    ];
    userDirectories = [
      "Desktop"
      "nixos-config"
      "pentest"
      ".config"
      ".local/share"
      ".local/state"
      "nix-custompkgs"
      "nix-custompkg-priv"
      "nix-mcp"
    ];
    userFiles = [
      "link.txt"
      ".bash_history"
    ];
  };

  nixosConfig =
    { config, ... }:
    {
      services.accounts-daemon.enable = true;

      systemd.tmpfiles.settings."10-user-directories" = lib.listToAttrs (
        map (dir: {
          name = "${config.my.dataPath}/${dir}";
          value.d = {
            mode = "0755";
            user = config.my.user.name;
            group = "users";
          };
        }) userDirs
      );

      systemd.tmpfiles.settings."10-accounts-service" = {
        "/var/lib/AccountsService".d = {
          mode = "0755";
          user = "root";
          group = "root";
        };
        "/var/lib/AccountsService/icons".d = {
          mode = "0755";
          user = "root";
          group = "root";
        };
        "/var/lib/AccountsService/users".d = {
          mode = "0755";
          user = "root";
          group = "root";
        };
        "/var/lib/AccountsService/icons/${config.my.user.name}"."C+" = {
          argument = config.sops.secrets."foto-profile".path;
          mode = "0644";
          user = "root";
          group = "root";
        };
        "/var/lib/AccountsService/users/${config.my.user.name}"."f+" = {
          argument = ''
            [User]
            Icon=/var/lib/AccountsService/icons/${config.my.user.name}
          '';
          mode = "0644";
          user = "root";
          group = "root";
        };
      };

      sops.secrets."foto-profile" = {
        format = "binary";
        owner = config.my.user.name;
        sopsFile = ./secrets/foto-profile.enc;
      };
    };

  hmConfig =
    hmOpts:
    let
      photoPath = hmOpts.osConfig.sops.secrets."foto-profile".path;
    in
    {
      home.file = selfLib.mkHmSymlinks hmOpts.config (
        (lib.genAttrs userSymlinkDirs (dir: "${hmOpts.osConfig.my.dataPath}/${dir}"))
        // {
          ".face.icon" = photoPath;
          ".face" = photoPath;
        }
      );
    };
}
