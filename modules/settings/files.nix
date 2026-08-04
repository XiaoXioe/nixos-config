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
    systemd.tmpfiles.rules = [
      "d /mnt/data_btrfs/containers 0755 ${config.my.user.name} users - -"
      "d /mnt/data_btrfs/PersistentData 0755 ${config.my.user.name} users - -"
      # Konfigurasi AccountsService agar SDDM dan DMS bisa membaca foto profil
      "d /var/lib/AccountsService 0755 root root - -"
      "d /var/lib/AccountsService/icons 0755 root root - -"
      "d /var/lib/AccountsService/users 0755 root root - -"
      "C+ /var/lib/AccountsService/icons/${config.my.user.name} 0444 root root - ${
        config.sops.secrets."foto-profile".path
      }"
      "f+ /var/lib/AccountsService/users/${config.my.user.name} 0644 root root - [User]\\nIcon=/var/lib/AccountsService/icons/${config.my.user.name}\\n"
    ];

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
