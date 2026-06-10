{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.system.services.base;
in
{
  options.my.system.services.base = {
    enable =
      lib.mkEnableOption "system services (thermald, flatpak, udisks2, journald, udev, coredump, btrfs scrub, vnstat)"
      // {
        default = true;
      };
  };

  config = lib.mkIf cfg.enable {
    services = {
      guix.enable = true;
      thermald.enable = true;
      flatpak.enable = true;
      udisks2.enable = true;
      vnstat.enable = true;

      btrfs.autoScrub = {
        enable = true;
        interval = "*-*-01 10:00";
      };

      journald.extraConfig = ''
        SystemMaxUse=100M
        SystemMaxFileSize=10M
        Storage=persistent
        SyncIntervalSec=5m
        MaxRetentionSec=7day
      '';

      udev.extraRules = ''
        ACTION=="add|change", KERNEL=="sd[a-z]|mmcblk[0-9]*|nvme[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="kyber"
        ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"

        ACTION=="add|change", SUBSYSTEM=="net", RUN+="${pkgs.ethtool}/bin/ethtool -K $name gro off gso off tso off"
      '';
    };

    systemd.coredump = {
      enable = true;
      settings.Coredump = {
        Storage = "external";
        Compress = "yes";
        ExternalSizeMax = "500M";
        ProcessSizeMax = "50M";
      };
    };
  };
}
