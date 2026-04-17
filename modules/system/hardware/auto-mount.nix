{
  config,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.system.auto-mount;
in
{
  options.my.system.auto-mount = {
    enable = selfLib.mkBoolOpt false "system automatic partition mounting";
    dataDevice =
      selfLib.mkOpt lib.types.str "/dev/disk/by-uuid/365EE7F85EE7AEB5"
        "The UUID for the data partition";

    btrfsDevice =
      selfLib.mkOpt lib.types.str "/dev/disk/by-uuid/7cecb23a-1617-4376-8fe0-f459a44c832b"
        "The UUID for the btrfs data partition";

    btrfsRoot =
      selfLib.mkOpt lib.types.str "/dev/disk/by-uuid/9617790f-27d0-460e-8f00-fa94f1d0e68d"
        "The UUID for the btrfs root partition";
  };

  config = lib.mkIf cfg.enable {
    fileSystems."/mnt/data" = {
      device = cfg.dataDevice;
      fsType = "ntfs3";
      options = [
        "rw"
        "uid=1000"
        "gid=100"
        # Mengubah mask menjadi 0000 agar tidak ada hak akses yang dikurangi
        "dmask=0000"
        "fmask=0000"
        "exec" # Mengizinkan eksekusi di level filesystem
        # "nofail"
        # "noauto"                       # Mencegah mount paksa saat awal booting
        "noatime"
        "x-systemd.automount" # Melakukan mount seketika saat folder diakses
        "x-systemd.mount-timeout=30s" # Timeout jika mount gagal (tidak blocking)
        "force"
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
      options = [ "bind" ];
    };
  };
}
