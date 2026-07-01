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
    # Anda harus menambahkan ini ke dalam berkas secrets/secrets.yaml Anda
    sops.secrets."restic-password" = { };
    sops.secrets."restic-env" = { };

    # Pastikan rclone terinstal di sistem karena kita menggunakannya sebagai backend
    environment.systemPackages = [ pkgs.rclone ];

    services.restic.backups."data-utama" = {
      # Ganti "semua-drive" dengan nama remote rclone Anda yang sebenarnya
      repository = "rclone:semua-drive:NixOS-Backup";
      
      # Referensi ke file rahasia
      passwordFile = config.sops.secrets."restic-password".path;
      
      # Environment file digunakan untuk konfigurasi tambahan Rclone (opsional)
      # environmentFile = config.sops.secrets."restic-env".path;
      
      # Apa saja yang akan dicadangkan
      paths = [
        "/persist/home/${config.my.user.name}/Documents"
        "/persist/home/${config.my.user.name}/Pictures"
        "/persist/home/${config.my.user.name}/PersistentData"
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
  };
}
