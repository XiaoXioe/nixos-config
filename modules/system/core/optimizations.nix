{
  config,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.system.optimizations;
in
{
  options.my.system.optimizations = {
    enable = selfLib.mkBoolOpt false "system optimizations";
  };

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
        "i915.enable_guc=0"
        # "mitigations=off"
        "i915.enable_fbc=0"
        "i915.enable_psr=0"
        # "quiet"
        "i915.modeset=1"
        "psi=1"
        # Mematikan USB autosuspend di level kernel
        "usbcore.autosuspend=-1"
      ];

      kernel = {
        sysctl = {
          "net.core.default_qdisc" = "cake";
          "net.ipv4.tcp_congestion_control" = "bbr";

          "vm.swappiness" = 100;
          "vm.page-cluster" = 0;
          "vm.vfs_cache_pressure" = 50; # Menjaga cache inode Btrfs lebih lama di memori agar pencarian file lebih instan
          "vm.dirty_ratio" = 10;
          "vm.dirty_background_ratio" = 5;
          "vm.watermark_scale_factor" = 125;
          "vm.watermark_boost_factor" = 0;

          "net.ipv6.conf.all.disable_ipv6" = 1;
          "net.ipv6.conf.default.disable_ipv6" = 1;
          "net.ipv6.conf.lo.disable_ipv6" = 1;

          # Meningkatkan resolusi maksimal timer yang bisa diminta oleh aplikasi di userspace (dari 64 ke 3072)
          "dev.hpet.max-user-freq" = 3072;

          # Memperbesar buffer software untuk menampung paket saat ring buffer hardware (256) penuh
          "net.core.netdev_max_backlog" = 16384;

          # Menyiapkan tabel untuk Receive Flow Steering (RFS) agar kernel melacak arus koneksi
          "net.core.rps_sock_flow_entries" = 32768;
        };
      };
    };

    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = 200;
      priority = 100;
    };
  };
}
