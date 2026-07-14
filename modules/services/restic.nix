{
  config,
  lib,
  pkgs,
  selfLib,
  ...
}:

let
  resticRepo = "rclone:union-raid1-4acc-crypt:NixOS-Backup";
  mountPoint = "/home/${config.my.user.name}/ResticBackup";
  proxyEnv = {
    HTTP_PROXY = "socks5://127.0.0.1:40000";
    HTTPS_PROXY = "socks5://127.0.0.1:40000";
    ALL_PROXY = "socks5://127.0.0.1:40000";
    NO_PROXY = "localhost,127.0.0.1";
  };
in

selfLib.mkModule {
  name = "services.restic";
  description = "Restic Backup Service via Rclone";

  nixosConfig = {
    # Deklarasi secret sops-nix untuk restic
    sops.secrets."restic-password" = { };

    # Pastikan rclone terinstal di sistem karena kita menggunakannya sebagai backend
    environment.systemPackages = [ pkgs.rclone ];

    services.restic.backups."data-utama" = {
      repository = resticRepo;

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
        "/mnt/data/backup-cloud"
      ];

      exclude = [
        ".cache"
        "venv"
        ".venv"
        "node_modules"
        "dataset"
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

    systemd.services."restic-backups-data-utama" = {
      environment = proxyEnv // {
        RCLONE_CONFIG = lib.mkForce "/run/restic-backups-data-utama/rclone.conf";
      };
      serviceConfig.ExecStartPre = lib.mkBefore [
        (pkgs.writeShellScript "restic-backups-data-utama-copy-rclone-config" ''
          ${pkgs.coreutils}/bin/cp ${
            config.sops.secrets."rclone.conf".path
          } /run/restic-backups-data-utama/rclone.conf
          ${pkgs.coreutils}/bin/chmod 600 /run/restic-backups-data-utama/rclone.conf
        '')
      ];
    };

    # ── Restic Mount (on-demand) ──────────────────────────────────────
    # Akses cadangan sebagai filesystem FUSE di ~/ResticBackup
    # Nyalakan:  sudo systemctl start restic-mount
    # Matikan:   sudo systemctl stop restic-mount
    systemd.services."restic-mount" = {
      description = "Mount Restic Backup Repository (on-demand)";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      # Tidak ada wantedBy — layanan ini hanya dijalankan secara manual

      environment = proxyEnv // {
        RCLONE_CONFIG = "/run/restic-mount/rclone.conf";
        RESTIC_REPOSITORY = resticRepo;
        RESTIC_PASSWORD_FILE = config.sops.secrets."restic-password".path;
      };

      path = [
        "/run/wrappers"
        pkgs.fuse3
      ];

      serviceConfig = {
        Type = "simple";
        RuntimeDirectory = "restic-mount";
        ExecStartPre = [
          "-${pkgs.fuse3}/bin/fusermount3 -uz ${mountPoint}"
          "${pkgs.coreutils}/bin/mkdir -p ${mountPoint}"
          (pkgs.writeShellScript "restic-mount-copy-rclone-config" ''
            ${pkgs.coreutils}/bin/cp ${config.sops.secrets."rclone.conf".path} /run/restic-mount/rclone.conf
            ${pkgs.coreutils}/bin/chmod 600 /run/restic-mount/rclone.conf
          '')
        ];
        ExecStart = "${pkgs.restic}/bin/restic mount ${mountPoint} --allow-other --no-lock";
        ExecStop = "${pkgs.fuse3}/bin/fusermount3 -uz ${mountPoint}";
        CacheDirectory = "restic-mount";
        Restart = "on-failure";
        RestartSec = "10s";
      };
    };
  };
}
