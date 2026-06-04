# Automatic filesystem mounting for NTFS data and BTRFS partitions.
{
  config,
  lib,
  ...
}:
let
  cfg = config.my.system.hardware.auto-mount;
in
{
  options.my.system.hardware.auto-mount = {
    enable = lib.mkEnableOption "automatic partition mounting";
    dataDevice = lib.mkOption {
      type = lib.types.str;
      default = "/dev/disk/by-uuid/365EE7F85EE7AEB5";
      description = "Device path for the NTFS data partition.";
    };
    btrfsDevice = lib.mkOption {
      type = lib.types.str;
      default = "/dev/disk/by-uuid/7cecb23a-1617-4376-8fe0-f459a44c832b";
      description = "Device path for the BTRFS data partition.";
    };
    btrfsRoot = lib.mkOption {
      type = lib.types.str;
      default = "/dev/disk/by-uuid/f888825f-bdb2-4dca-9c58-b5dd4f6a39d8";
      description = "Device path for the BTRFS root partition.";
    };
  };

  config = lib.mkIf cfg.enable {
    fileSystems."/mnt/data" = {
      device = cfg.dataDevice;
      fsType = "ntfs-3g";
      options = [
        "rw"
        "uid=1000"
        "gid=100"
        "dmask=0000"
        "fmask=0000"
        "exec"
        "nofail"
        "noatime"
        "x-systemd.automount"
        "x-systemd.mount-timeout=30s"
      ];
    };

    fileSystems."/mnt/data_btrfs" = {
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

    fileSystems."/mnt/btrfs-root" = {
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

    fileSystems."/var/lib/flatpak" = {
      device = "/mnt/data_btrfs/flatpak-system";
      fsType = "none";
      options = [ "bind" ];
    };
  };
}
