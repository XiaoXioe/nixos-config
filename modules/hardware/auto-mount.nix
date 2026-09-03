{
  config,
  lib,
  selfLib,
  ...
}:
selfLib.mkModule {
  name = "hardware.auto-mount";
  options = {
    btrfsDevice = lib.mkOption {
      type = lib.types.str;
      default = "/dev/disk/by-uuid/b37ce34a-51ef-4022-a728-43b9293e7da4";
      description = "Device path for the BTRFS data partition.";
    };
  };

  nixosConfig =
    let
      cfg = config.my.hardware.auto-mount;
    in
    {
      fileSystems."${config.my.dataPath}" = {
        device = cfg.btrfsDevice;
        fsType = "btrfs";
        options = [
          "compress=zstd:6"
          "noatime"
          "nofail"
          "discard=async"
          "space_cache=v2"
          "x-systemd.before=local-fs.target"
        ];
      };
    };
}
