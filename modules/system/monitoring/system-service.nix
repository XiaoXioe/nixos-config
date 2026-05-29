{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.services.system-service;
in
{
  options.my.services.system-service = {
    enable = lib.mkEnableOption "All Service systemd";
  };
  config = lib.mkIf cfg.enable {
    # services.fstrim.enable = true;
    services.thermald.enable = true;
    services.flatpak.enable = true;
    services.udisks2.enable = true;

    # Limit systemd journal size to prevent /var/log/ bloat
    services.journald.extraConfig = ''
      SystemMaxUse=100M
      SystemMaxFileSize=10M
      Storage=persistent
      SyncIntervalSec=5m
      MaxRetentionSec=7day
    '';

    # Udev rules for I/O scheduler
    services.udev.extraRules = ''
      ACTION=="add|change", KERNEL=="sd[a-z]|mmcblk[0-9]*|nvme[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="kyber"
      ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"

      ACTION=="add|change", SUBSYSTEM=="net", RUN+="${pkgs.ethtool}/bin/ethtool -K $name gro off gso off tso off"
    '';

    systemd.coredump = {
      enable = true;
      settings.Coredump = {
        # Persist to disk, not RAM
        Storage = "external";
        # Memaksa kompresi zstd
        Compress = "yes";
        # Batas maksimal total semua coredump di disk
        ExternalSizeMax = "500M";
        # Batas maksimal satu file coredump
        ProcessSizeMax = "50M";
      };
    };

    # Pindahkan ini ke HDD JIKA /tmp di RAM tidak muat lagi
    # systemd.services.nix-daemon.environment.TMPDIR = "/mnt/data_btrfs/nix-build";

    # --- Btrfs Auto Scrub ---
    # Mengaktifkan proses scrub otomatis untuk menjaga kesehatan data (mencegah bit rot)
    services.btrfs.autoScrub = {
      enable = true;
      interval = "*-*-01 10:00";
    };

    # --- vnStat Network Monitor ---
    # Mengaktifkan daemon vnstat untuk merekam lalu lintas jaringan
    services.vnstat.enable = true;
  };
}
