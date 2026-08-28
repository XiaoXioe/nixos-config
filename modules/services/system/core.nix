{
  lib,
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "services.system.core";
  description = "Core system services (vnstat, udisks2, fstrim, btrfs scrub)";

  preservation = {
    persist = true;
    directories = [
      "/var/lib/systemd"
      {
        directory = "/var/lib/vnstat";
        user = "vnstatd";
        group = "vnstatd";
        mode = "0755";
      }
    ];
  };

  nixosConfig = {
    environment.systemPackages = [ pkgs.hdparm ];

    services = {
      speechd.enable = lib.mkForce false;
      thermald.enable = true;
      udisks2.enable = true;
      vnstat.enable = true;
      fstrim.enable = true;

      btrfs.autoScrub = {
        enable = true;
        interval = "*-*-01 10:00";
      };

      journald.extraConfig = ''
        SystemMaxUse=250M
        SystemMaxFileSize=50M
        Storage=persistent
        SyncIntervalSec=5m
        MaxRetentionSec=7day
      '';

      udev.extraRules = ''
        ACTION=="add|change", KERNEL=="sd[a-z]|mmcblk[0-9]*|nvme[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="kyber"
        ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"

        # Nonaktifkan APM spin-down dan Standby Timeout untuk HDD mekanik (rotational=1)
        ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", RUN+="${pkgs.hdparm}/bin/hdparm -B 254 -S 0 /dev/%k"
      '';
    };

    systemd = {
      tmpfiles.rules = [
        "Z /var/lib/vnstat 0755 vnstatd vnstatd -"
        "Z /persist/var/lib/vnstat 0755 vnstatd vnstatd -"
      ];

      timers = {
        fstrim.timerConfig.Persistent = false;
        # mkForce diperlukan karena nixpkgs default Persistent=true pada btrfs-scrub.
        # Tanpa ini, scrub langsung berjalan setelah setiap reboot jika melewatkan jadwal —
        # scrub berat, lebih baik menunggu jadwal normal berikutnya.
        btrfs-scrub--.timerConfig.Persistent = lib.mkForce false;
        # mkForce diperlukan karena nixpkgs default Persistent=true pada btrfs-scrub.
        # Tanpa ini, scrub langsung berjalan setelah setiap reboot jika melewatkan jadwal —
        # scrub berat, lebih baik menunggu jadwal normal berikutnya.
        btrfs-scrub-mnt-data_btrfs.timerConfig.Persistent = lib.mkForce false;
      };

      coredump.enable = false;
    };
  };
}
