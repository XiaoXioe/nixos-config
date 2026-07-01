{ selfLib, ... }:
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
        "vm.watermark_scale_factor" = 125;
        "vm.watermark_boost_factor" = 0;
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
