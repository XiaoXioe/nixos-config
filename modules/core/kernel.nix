{ pkgs, selfLib, ... }:
selfLib.mkModule {
  name = "core.kernel";
  nixosConfig = {
    boot = {
      kernelPackages = pkgs.linuxPackages_zen;

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
        # FBC dan PSR dinonaktifkan karena menyebabkan rendering artifacts
        # pada Intel Ivy Bridge (Gen 3) — bug hardware yang diketahui
        "i915.enable_fbc=0"
        "i915.enable_psr=0"
        # "mitigations=off"
        "psi=1"
        # Disable USB autosuspend at kernel level
        # "usbcore.autosuspend=-1"
        # Batasi C-state untuk mengatasi masalah mati mendadak saat idle/browsing
        # "intel_idle.max_cstate=1"
      ];

      kernel = {
        sysctl = {
          "kernel.core_pattern" = "/dev/null";
          "net.core.default_qdisc" = "cake";
          "net.ipv4.tcp_congestion_control" = "bbr";

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
  };
}
