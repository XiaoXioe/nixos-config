{
  config,
  lib,
  ...
}:
let
  cfg = config.my.user.settings.settings;
in
{
  options.my.user.settings.settings = {
    enable = lib.mkEnableOption "Home file settings";
  };

  config = lib.mkIf cfg.enable {
    home.file.".var/app".source =
      config.lib.file.mkOutOfStoreSymlink "/mnt/data_btrfs/flatpak-userdata";
    home.file.".local/share/flatpak".source =
      config.lib.file.mkOutOfStoreSymlink "/mnt/data_btrfs/flatpak-local";
    home.file.".local/share/containers".source =
      config.lib.file.mkOutOfStoreSymlink "/mnt/data_btrfs/containers";

    home.file."Documents".source = config.lib.file.mkOutOfStoreSymlink "/mnt/data/Documents";
    home.file."Downloads".source = config.lib.file.mkOutOfStoreSymlink "/mnt/data/Downloads";
    home.file."Pictures".source = config.lib.file.mkOutOfStoreSymlink "/mnt/data/Pictures";
    home.file."Videos".source = config.lib.file.mkOutOfStoreSymlink "/mnt/data/Videos";
    home.file."Music".source = config.lib.file.mkOutOfStoreSymlink "/mnt/data/Music";

    home.file = {
      ".face.icon".source = config.lib.file.mkOutOfStoreSymlink "/run/secrets/foto-profile";
      ".face".source = config.lib.file.mkOutOfStoreSymlink "/run/secrets/foto-profile";
    };
  };
}
