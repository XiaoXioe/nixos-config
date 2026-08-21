{
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "core.kernel.settings";
  description = "Common sysctl, boot modules, and kernel parameters for all kernels";

  options = { };

  nixosConfig = {
    boot = {
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
        "psi=1"
        "usbcore.autosuspend=-1"
      ];

      kernel = {
        sysctl = {
          # Mengatasi silent drop paket TLS/NAR besar pada WireGuard / WARP
          "net.ipv4.tcp_mtu_probing" = 1;
          "net.ipv4.tcp_base_mss" = 1024;

          "net.core.default_qdisc" = "cake";
          "net.ipv4.tcp_congestion_control" = "bbr";

          # Meningkatkan resolusi maksimal timer
          "dev.hpet.max-user-freq" = 3072;

          # Buffer jaringan
          "net.core.netdev_max_backlog" = 16384;
          "net.core.rps_sock_flow_entries" = 32768;

          "net.ipv4.tcp_fastopen" = 3;
          "fs.inotify.max_user_watches" = 524288;
          "fs.inotify.max_user_instances" = 8192;
        };
      };
    };
  };
}
