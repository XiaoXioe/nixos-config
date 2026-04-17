{
  config,
  lib,
  pkgs,
  selfLib,
  ...
}:

let
  cfg = config.my.services.system-service;
in
{
  options.my.services.system-service = {
    enable = selfLib.mkBoolOpt false "All Service systemd";
  };
  config = lib.mkIf cfg.enable {
    # services.fstrim.enable = true;
    services.thermald.enable = true;
    services.flatpak.enable = true;
    services.udisks2.enable = true;

    # services.udiskie = {
    #   enable = true;
    #   automount = true;
    #   notify = true; # Memunculkan notifikasi saat USB dicolok
    # };

    # Batasi Log Systemd agar tidak memakan ruang di /var/log/ (Persistensi)
    services.journald.extraConfig = ''
      SystemMaxUse=100M
      SystemMaxFileSize=10M
      Storage=persistent
      SyncIntervalSec=5m
      MaxRetentionSec=7day
    '';

    #services.gnome.evolution-data-server.enable = true;
    #security.pam.services.sddm.enableKwallet = true;

    # Konfigurasi Udev untuk I/O Scheduler
    services.udev.extraRules = ''
      # Gunakan 'kyber' untuk SSD/NVMe (non-rotational)
      ACTION=="add|change", KERNEL=="sd[a-z]|mmcblk[0-9]*|nvme[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="kyber"

      # Pastikan HDD (rotational) tetap menggunakan 'bfq'
      ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"

      # Udev rule untuk memberikan akses RTC ke user biasa yang masuk di grup wheel
      ACTION=="add|change", SUBSYSTEM=="net", RUN+="${pkgs.ethtool}/bin/ethtool -K $name gro off gso off tso off"

      # Mengecualikan Mouse, Keyboard, dan Gamepad dari aturan USB Auto-Suspend
      ACTION=="add", SUBSYSTEM=="usb", ATTR{bInterfaceClass}=="03", ATTR{power/control}="on"
    '';

    systemd.coredump = {
      enable = true;
      extraConfig = ''
        # Menyimpan ke disk, bukan di RAM (journal)
        Storage=external
        # Memaksa kompresi zstd
        Compress=yes
        # Batas maksimal total semua coredump di disk
        ExternalSizeMax=500M
        # Batas maksimal satu file coredump
        ProcessSizeMax=50M
      '';
    };

    # Pindahkan ini ke HDD JIKA /tmp di RAM tidak muat lagi
    # systemd.services.nix-daemon.environment.TMPDIR = "/mnt/data_btrfs/nix-build";

    # --- Btrfs Auto Scrub ---
    # Mengaktifkan proses scrub otomatis untuk menjaga kesehatan data (mencegah bit rot)
    services.btrfs.autoScrub = {
      enable = true;
      # Berjalan setiap hari Selasa jam 10 pagi
      interval = "Tue 10:00";
    };

    # --- vnStat Network Monitor ---
    # Mengaktifkan daemon vnstat untuk merekam lalu lintas jaringan
    services.vnstat.enable = true;
  };
}
