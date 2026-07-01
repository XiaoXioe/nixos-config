{
  config,
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "services.restic";
  description = "Restic Backup Service via Rclone";

  nixosConfig = {
    # Deklarasi secret sops-nix untuk restic
    sops.secrets."restic-password" = { };

    # Pastikan rclone terinstal di sistem karena kita menggunakannya sebagai backend
    environment.systemPackages = [ pkgs.rclone ];

    services.restic.backups."data-utama" = {
      repository = "rclone:union-raid1-4acc-crypt:NixOS-Backup";

      rcloneConfigFile = config.sops.secrets."rclone.conf".path;

      # Referensi ke file rahasia
      passwordFile = config.sops.secrets."restic-password".path;

      # Apa saja yang akan dicadangkan
      paths = [
        "/home/${config.my.user.name}/Documents"
        "/home/${config.my.user.name}/Pictures"
        "/home/${config.my.user.name}/Music"
        "/persist/home/${config.my.user.name}/pentest"
        "/persist/home/${config.my.user.name}/PersistentData"
      ];

      exclude = [
        ".cache"
        "node_modules"
      ];

      # Menginisialisasi repositori jika belum ada
      initialize = true;

      timerConfig = {
        OnCalendar = "02:00:00"; # Berjalan setiap jam 2 pagi
        Persistent = true;
        RandomizedDelaySec = "10m";
      };

      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 6"
      ];
    };

    systemd.services."restic-backups-data-utama".environment = {
      HTTP_PROXY = "socks5://127.0.0.1:40000";
      HTTPS_PROXY = "socks5://127.0.0.1:40000";
      ALL_PROXY = "socks5://127.0.0.1:40000";
      NO_PROXY = "localhost,127.0.0.1";
    };
  };
}
