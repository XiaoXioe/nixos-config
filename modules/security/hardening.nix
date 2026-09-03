{
  pkgs,
  selfLib,
  ...
}:
selfLib.mkModule {
  name = "security.hardening";

  nixosConfig = {
    boot.kernel.sysctl = {
      "kernel.dmesg_restrict" = 1;
      "kernel.kptr_restrict" = 2;
      "kernel.unprivileged_bpf_disabled" = 1;
      "net.ipv4.conf.all.rp_filter" = 1;
      "net.ipv4.conf.default.rp_filter" = 1;

      # Batasi ptrace ke parent/child saja (scope 1).
      # Scope 0 dihapus — terlalu permissive (semua proses bisa ptrace semua proses).
      # Untuk game wrapper (Sober, dll), gunakan firejail profile atau capabilities spesifik.
      "kernel.yama.ptrace_scope" = 1;
      # Lindungi dari SYN flood.
      "net.ipv4.tcp_syncookies" = 1;
      # Nonaktifkan pemuatan kernel baru via kexec (perkecil permukaan serangan).
      "kernel.kexec_load_disabled" = 1;
    };

    programs.firejail.enable = true;

    # Set hard & soft limit core dump = 0 untuk seluruh sesi login pengguna (PAM)
    security.pam.loginLimits = [
      {
        domain = "*";
        item = "core";
        type = "-";
        value = "0";
      }
    ];

    # Nonaktifkan core limit & coredump di level systemd manager
    systemd = {
      coredump.enable = false;
      settings.Manager = {
        DefaultLimitCORE = "0";
      };
      user.extraConfig = ''
        DefaultLimitCORE=0
      '';
    };

    security = {
      apparmor = {
        enable = true;
        enableCache = true;
        packages = [ pkgs.apparmor-profiles ];
      };
    };
  };
}
