{
  config,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.user.settings;
in
{
  options.my.user.settings = {
    enable = selfLib.mkBoolOpt false "Home file settings";
  };

  config = lib.mkIf cfg.enable {
    home.file.".var/app".source =
      config.lib.file.mkOutOfStoreSymlink "/mnt/data_btrfs/flatpak-userdata";
    home.file.".local/share/flatpak".source =
      config.lib.file.mkOutOfStoreSymlink "/mnt/data_btrfs/flatpak-local";
    home.file.".local/share/containers".source =
      config.lib.file.mkOutOfStoreSymlink "/mnt/data_btrfs/containers";
  };
}
