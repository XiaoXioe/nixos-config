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
      sopsFile = selfLib.secretBinary "media/foto-profile.enc";
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
