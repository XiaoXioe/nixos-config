{
  pkgs,
  config,
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

      # Batasi ptrace ke proses admin saja (cegah proses non-root mengintip
      # memori proses lain). Diubah ke 0 agar Sober / aplikasi wrapper game bisa berjalan.
      "kernel.yama.ptrace_scope" = 0;
      # Lindungi dari SYN flood.
      "net.ipv4.tcp_syncookies" = 1;
      # Nonaktifkan pemuatan kernel baru via kexec (perkecil permukaan serangan).
      "kernel.kexec_load_disabled" = 1;
    };

    programs.firejail.enable = true;

    services = {
      fail2ban = {
        enable = false;
        ignoreIP = [
          "127.0.0.0/8"
          "192.168.0.0/16"
        ];
      };
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
