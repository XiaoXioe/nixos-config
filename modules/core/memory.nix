{ config, selfLib, ... }:
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

    # Optimize I/O queue scheduler for SATA SSDs (non-rotational drives) to reduce I/O latency
    services.udev.extraRules = ''
      ACTION=="add|change", KERNEL=="sd[a-z]*|mmcblk[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="kyber"
    '';

    fileSystems."/home/${config.my.user.name}/.cache/nix" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [
        "rw"
        "nodev"
        "nosuid"
        "size=2G"
        "mode=0700"
        "uid=1000"
        "gid=100"
      ];
    };

    fileSystems."/root/.cache/nix" = {
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

    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = 100;
      priority = 50;
    };
  };
}
