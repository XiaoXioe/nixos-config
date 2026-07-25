{
  config,
  inputs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "settings.files";
  description = "Home file settings";

  nixosConfig = {
    systemd.tmpfiles.rules = [
      "d /mnt/data_btrfs/containers 0755 ${config.my.user.name} users - -"
      "d /mnt/data_btrfs/PersistentData 0755 ${config.my.user.name} users - -"
    ];

    sops.secrets."foto-profile" = {
      format = "binary";
      owner = config.my.user.name;
      sopsFile = selfLib.secretBinary "foto-profile.enc";
    };
  };

  hmConfig = hmOpts: {
    home.file."Documents".source = hmOpts.config.lib.file.mkOutOfStoreSymlink "/mnt/data/Documents";
    home.file."Downloads".source = hmOpts.config.lib.file.mkOutOfStoreSymlink "/mnt/data/Downloads";
    home.file."Pictures".source = hmOpts.config.lib.file.mkOutOfStoreSymlink "/mnt/data/Pictures";
    home.file."Videos".source = hmOpts.config.lib.file.mkOutOfStoreSymlink "/mnt/data/Videos";
    home.file."Music".source = hmOpts.config.lib.file.mkOutOfStoreSymlink "/mnt/data/Music";
    home.file."PersistentData".source =
      hmOpts.config.lib.file.mkOutOfStoreSymlink "/mnt/data_btrfs/PersistentData";

    home.file = {
      ".face.icon".source =
        hmOpts.config.lib.file.mkOutOfStoreSymlink
          hmOpts.osConfig.sops.secrets."foto-profile".path;
      ".face".source =
        hmOpts.config.lib.file.mkOutOfStoreSymlink
          hmOpts.osConfig.sops.secrets."foto-profile".path;
    };
  };
}
