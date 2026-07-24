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
in

selfLib.mkModule {
  name = "services.storage.restic";
  description = "Restic Backup Service via Rclone";

  nixosConfig = {
    # Deklarasi secret sops-nix untuk restic
    sops.secrets."restic-password" = {
      owner = config.my.user.name;
    };

    # Pastikan rclone terinstal di sistem karena kita menggunakannya sebagai backend,
    # dan bungkus (wrap) rclone agar menggunakan proxy, tanpa mencemari environment Restic
    environment.systemPackages = [
      (pkgs.symlinkJoin {
        name = "rclone-proxy-wrapper";
        paths = [ pkgs.rclone ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/rclone \
            --set HTTP_PROXY "socks5h://127.0.0.1:40000" \
            --set HTTPS_PROXY "socks5h://127.0.0.1:40000" \
            --set ALL_PROXY "socks5h://127.0.0.1:40000"
        '';
      })
    ];

    services.restic.backups."data-utama" = {
      repository = resticRepo;

      rcloneConfigFile = config.sops.secrets."rclone.conf".path;

      # Referensi ke file rahasia
      passwordFile = config.sops.secrets."restic-password".path;

      # Apa saja yang akan dicadangkan
      paths = [
        "/home/${config.my.user.name}/.gemini"
        "/home/${config.my.user.name}/.ssh"
        "/home/${config.my.user.name}/.gnupg"
        "/home/${config.my.user.name}/.thunderbird"
        "/mnt/data/Documents"
        "/mnt/data/Pictures"
        "/mnt/data/Music"
        "/persist/etc/ssh"
        "/persist/home/${config.my.user.name}/nixos-config"
        "/persist/home/${config.my.user.name}/nix-custompkgs"
        "/persist/home/${config.my.user.name}/nix-custompkg-priv"
        "/persist/home/${config.my.user.name}/nix-mcp"
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
        "ml"
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
      restartIfChanged = false;
      after = [
        "network-online.target"
        "wireproxy-warp.service"
      ];
      wants = [
        "network-online.target"
        "wireproxy-warp.service"
      ];
      environment = {
        RCLONE_CONFIG = lib.mkForce "/run/restic-backups-data-utama/rclone.conf";
        RESTIC_PROGRESS_FPS = "0.016666";
        HTTP_PROXY = "socks5h://127.0.0.1:40000";
        HTTPS_PROXY = "socks5h://127.0.0.1:40000";
        ALL_PROXY = "socks5h://127.0.0.1:40000";
        NO_PROXY = "localhost,127.0.0.1,::1";
      };
      serviceConfig.ExecStartPre = lib.mkBefore [
        (pkgs.writeShellScript "restic-backups-data-utama-wait-proxy" ''
          # Wait for SOCKS5 proxy port 40000 to be online and working
          for i in {1..30}; do
            if ${pkgs.curl}/bin/curl -s --max-time 3 -o /dev/null --proxy socks5h://127.0.0.1:40000 https://www.google.com; then
              echo "Proxy 40000 is online."
              exit 0
            fi
            ${pkgs.coreutils}/bin/sleep 2
          done
          echo "WARNING: Proxy 40000 not responsive after 60s, proceeding anyway..."
        '')
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
      restartIfChanged = false;
      # Tidak ada wantedBy — layanan ini hanya dijalankan secara manual

      environment = {
        RCLONE_CONFIG = "/run/restic-mount/rclone.conf";
        RESTIC_REPOSITORY = resticRepo;
        RESTIC_PASSWORD_FILE = config.sops.secrets."restic-password".path;
        HTTP_PROXY = "socks5h://127.0.0.1:40000";
        HTTPS_PROXY = "socks5h://127.0.0.1:40000";
        ALL_PROXY = "socks5h://127.0.0.1:40000";
        NO_PROXY = "localhost,127.0.0.1,::1";
      };

      path = [
        "/run/wrappers"
        pkgs.fuse3
      ];

      serviceConfig = {
        Type = "simple";
        User = config.my.user.name;
        RuntimeDirectory = "restic-mount";
        ExecStartPre = [
          "+-${pkgs.fuse3}/bin/fusermount3 -uz ${mountPoint}"
          "+${pkgs.coreutils}/bin/mkdir -p ${mountPoint}"
          "+${pkgs.coreutils}/bin/chown ${config.my.user.name} ${mountPoint}"
          "+${pkgs.writeShellScript "restic-mount-copy-rclone-config" ''
            ${pkgs.coreutils}/bin/cp ${config.sops.secrets."rclone.conf".path} /run/restic-mount/rclone.conf
            ${pkgs.coreutils}/bin/chmod 600 /run/restic-mount/rclone.conf
            ${pkgs.coreutils}/bin/chown ${config.my.user.name} /run/restic-mount/rclone.conf
          ''}"
        ];
        ExecStart = "${pkgs.restic}/bin/restic mount ${mountPoint} --no-lock";
        ExecStop = "${pkgs.fuse3}/bin/fusermount3 -uz ${mountPoint}";
        CacheDirectory = "restic-mount";
        Restart = "on-failure";
        RestartSec = "10s";
      };
    };
  };
}
