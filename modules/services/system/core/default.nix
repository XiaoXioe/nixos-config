{
  lib,
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "services.system.core";

  nixosConfig = {
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
      '';
    };

    systemd.services.vnstat.serviceConfig.ExecStartPre = [
      "+${pkgs.coreutils}/bin/chown -R vnstatd:vnstatd /var/lib/vnstat"
    ];

    systemd.timers.fstrim.timerConfig.Persistent = false;
    systemd.timers.btrfs-scrub--.timerConfig.Persistent = lib.mkForce false;
    systemd.timers.btrfs-scrub-mnt-data_btrfs.timerConfig.Persistent = lib.mkForce false;

    systemd.coredump.enable = false;
  };
}
