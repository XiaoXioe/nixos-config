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
    btrfsRoot = lib.mkOption {
      type = lib.types.str;
      default = "/dev/disk/by-uuid/f888825f-bdb2-4dca-9c58-b5dd4f6a39d8";
      description = "Device path for the BTRFS root partition.";
    };
  };

  nixosConfig =
    let
      cfg = config.my.hardware.auto-mount;
    in
    {
      fileSystems = {

        "${config.my.dataPath}" = {
          device = cfg.btrfsDevice;
          fsType = "btrfs";
          options = [
            "compress=zstd:6"
            "noatime"
            "nofail"
            "discard=async"
            "space_cache=v2"
          ];
        };

        "/mnt/btrfs-root" = {
          device = cfg.btrfsRoot;
          fsType = "btrfs";
          options = [
            "subvolid=5"
            "defaults"
            "noatime"
            "noauto"
            "x-systemd.automount"
            "x-systemd.idle-timeout=1min"
          ];
        };

        "/var/lib/flatpak" = {
          device = "${config.my.dataPath}/flatpak-system";
          fsType = "none";
          options = [
            "bind"
            "nofail"
            "x-systemd.requires=${
              lib.replaceStrings [ "/" ] [ "-" ] (lib.removePrefix "/" config.my.dataPath)
            }.mount"
            "x-systemd.after=${
              lib.replaceStrings [ "/" ] [ "-" ] (lib.removePrefix "/" config.my.dataPath)
            }.mount"
          ];
        };
      };
    };
}
