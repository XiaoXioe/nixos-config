{
  config,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.core.optimizations;
in
{
  options = selfLib.mkNestedEnable "core.optimizations";

  config = lib.mkIf cfg.enable {
    powerManagement = {
      enable = true;
      cpuFreqGovernor = "schedutil";
    };

    boot = {
      tmp = {
        useTmpfs = true;
        tmpfsSize = "60%";
      };

      kernelModules = [
        "sch_cake"
        "tcp_bbr"
      ];

      initrd = {
        kernelModules = [
          "btrfs"
          "i915"
        ];
      };

      kernelParams = [
        "nmi_watchdog=0"
        "split_lock_mitigate=0"
        "transparent_hugepage=madvise"
        "i915.enable_guc=0"
        # "mitigations=off"
        "i915.enable_fbc=0"
        "i915.enable_psr=0"
        # "quiet"
        "i915.modeset=1"
        "psi=1"

        # Disable Render Standby (RC6)
        "i915.enable_rc6=0"
        # Disable USB autosuspend at kernel level
        # "usbcore.autosuspend=-1"
      ];

      kernel = {
        sysctl = {
          "net.core.default_qdisc" = "cake";
          "net.ipv4.tcp_congestion_control" = "bbr";

          "vm.swappiness" = 100;
          "vm.page-cluster" = 0;
          "vm.vfs_cache_pressure" = 50; # Keep Btrfs inode cache in memory longer for faster file lookups
          "vm.dirty_ratio" = 10;
          "vm.dirty_background_ratio" = 5;
          "vm.watermark_scale_factor" = 125;
          "vm.watermark_boost_factor" = 0;

          "net.ipv6.conf.all.disable_ipv6" = 1;
          "net.ipv6.conf.default.disable_ipv6" = 1;
          "net.ipv6.conf.lo.disable_ipv6" = 1;

          # Meningkatkan resolusi maksimal timer yang bisa diminta oleh aplikasi di userspace (dari 64 ke 3072)
          "dev.hpet.max-user-freq" = 3072;

          # Increase software buffer to handle packets when hardware ring buffer (256) is full
          "net.core.netdev_max_backlog" = 16384;

          # Set up Receive Flow Steering (RFS) table for kernel connection tracking
          "net.core.rps_sock_flow_entries" = 32768;

          "net.ipv4.tcp_fastopen" = 3;
          "fs.inotify.max_user_watches" = 524288;
          "fs.inotify.max_user_instances" = 8192;
        };
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
