{
  config,
  selfLib,
  ...
}:

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

  nixosConfig = {
    services.accounts-daemon.enable = true;

    systemd.tmpfiles.settings."10-accounts-service" = {
      "/mnt/data_btrfs/containers".d = {
        mode = "0755";
        user = config.my.user.name;
        group = "users";
      };
      "/mnt/data_btrfs/PersistentData".d = {
        mode = "0755";
        user = config.my.user.name;
        group = "users";
      };
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

  hmConfig = hmOpts: {
    home.file = selfLib.mkHmSymlinks hmOpts.config {
      "Documents" = "/mnt/data/Documents";
      "Downloads" = "/mnt/data/Downloads";
      "Pictures" = "/mnt/data/Pictures";
      "Videos" = "/mnt/data/Videos";
      "Music" = "/mnt/data/Music";
      "PersistentData" = "/mnt/data_btrfs/PersistentData";
      ".face.icon" = hmOpts.osConfig.sops.secrets."foto-profile".path;
      ".face" = hmOpts.osConfig.sops.secrets."foto-profile".path;
    };
  };
}
