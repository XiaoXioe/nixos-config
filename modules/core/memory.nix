{
  config,
  lib,
  selfLib,
  ...
}:
let
  # Ambil UID dan GID user secara dinamis dari konfigurasi NixOS.
  # Ini mencegah hardcoding uid=1000 yang fragile.
  userCfg = config.my.user;
  userUid = toString config.users.users.${userCfg.name}.uid;
  # GID grup 'users' (100) diambil dari lookup, dengan fallback ke 100
  userGid = toString (config.users.groups.users.gid or 100);
in
selfLib.mkModule {
  name = "core.memory";
  nixosConfig = {
    boot = {
      tmp = {
        useTmpfs = true;
        tmpfsSize = "60%";
      };

      kernel.sysctl = {
        "vm.swappiness" = 180;
        "vm.page-cluster" = 0;
        "vm.vfs_cache_pressure" = 50; # Keep Btrfs inode cache in memory longer for faster file lookups
        "vm.dirty_ratio" = 10;
        "vm.dirty_background_ratio" = 5;
        "vm.dirty_writeback_centisecs" = 1500; # Flush dirty pages every 15s (reduces SSD write spikes)
        "vm.dirty_expire_centisecs" = 3000; # Allow dirty pages to remain in RAM cache up to 30s
        "vm.watermark_scale_factor" = 125;
        "vm.watermark_boost_factor" = 0;
      };
    };

    fileSystems = {
      "/home/${config.my.user.name}/.cache/nix" = {
        device = "tmpfs";
        fsType = "tmpfs";
        options = [
          "rw"
          "nodev"
          "nosuid"
          "size=2G"
          "mode=0700"
          "uid=${userUid}"
          "gid=${userGid}"
        ];
      };
      "/root/.cache/nix" = {
        device = "tmpfs";
        fsType = "tmpfs";
        options = [
          "rw"
          "nodev"
          "nosuid"
          "size=1G"
          "mode=0700"
          "uid=0"
          "gid=0"
        ];
      };
    };

    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = 100;
      priority = 50;
    };
  };
}
