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
    # Secret declaration for restic password
    sops.secrets = {
      "restic-password" = {
        owner = config.my.user.name;
        mode = "0444";
      };
    };

    environment.systemPackages = [
      (pkgs.symlinkJoin {
        name = "rclone-proxy-wrapper";
        paths = [ pkgs.rclone ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild =
          let
            proxyEnv = (selfLib.network { inherit lib pkgs; }).warpProxyEnv;
          in
          ''
            wrapProgram $out/bin/rclone \
              --set HTTP_PROXY "${proxyEnv.HTTP_PROXY}" \
              --set HTTPS_PROXY "${proxyEnv.HTTPS_PROXY}" \
              --set ALL_PROXY "${proxyEnv.ALL_PROXY}"
          '';
      })
    ];

    services.restic.backups."data-utama" = {
      repository = resticRepo;
      rcloneConfigFile = config.sops.secrets."rclone.conf".path;
      passwordFile = config.sops.secrets."restic-password".path;

      paths = [
        "/home/${config.my.user.name}/.gemini"
        "/home/${config.my.user.name}/.ssh"
        "/home/${config.my.user.name}/.gnupg"
        "/home/${config.my.user.name}/.thunderbird"
        "/persist/home/${config.my.user.name}/nixos-config"
        "/persist/home/${config.my.user.name}/nix-custompkgs"
        "/persist/home/${config.my.user.name}/nix-custompkg-priv"
        "/persist/home/${config.my.user.name}/nix-mcp"
        "/persist/home/${config.my.user.name}/pentest"
        "/mnt/data/Documents"
        "/mnt/data/Pictures"
        "/mnt/data/Music"
        "/persist/etc/ssh"
        "/mnt/data_btrfs/PersistentData"
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

      initialize = true;

      timerConfig = {
        OnCalendar = "02:00:00";
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
      }
      // (selfLib.network { inherit lib pkgs; }).warpProxyEnv;

      serviceConfig.ExecStartPre = lib.mkBefore [
        ((selfLib.network { inherit lib pkgs; }).mkWarpWaitScript "restic-backups-data-utama-wait-proxy")
        (pkgs.writeShellScript "restic-backups-data-utama-copy-rclone-config" ''
          ${pkgs.coreutils}/bin/cp ${
            config.sops.secrets."rclone.conf".path
          } /run/restic-backups-data-utama/rclone.conf
          ${pkgs.coreutils}/bin/chmod 600 /run/restic-backups-data-utama/rclone.conf
        '')
      ];
    };
  };

  hmConfig = hmOpts: {
    systemd.user.services.restic-mount = {
      Unit = {
        Description = "Mount Restic Backup Repository (FUSE on-demand)";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
        "X-SwitchMethod" = "keep-old";
      };
      Service = {
        Type = "simple";
        ExecStartPre = [
          "${pkgs.coreutils}/bin/mkdir -p ${mountPoint}"
        ];
        ExecStart = pkgs.writeShellScript "restic-mount-start" ''
          set -euo pipefail

          ${(selfLib.network { inherit lib pkgs; }).mkWarpWaitScript "restic-mount-wait-proxy"}

          export RCLONE_CONFIG="${hmOpts.osConfig.sops.secrets."rclone.conf".path}"
          exec ${pkgs.restic}/bin/restic mount "${mountPoint}" \
            --repo "${resticRepo}" \
            --password-file "${hmOpts.osConfig.sops.secrets."restic-password".path}"
        '';
        ExecStop = "${pkgs.fuse3}/bin/fusermount3 -uz ${mountPoint}";
        Restart = "on-failure";
        RestartSec = "10s";
        Environment =
          lib.mapAttrsToList (n: v: "${n}=${v}")
            (selfLib.network { inherit lib pkgs; }).warpProxyEnv;
      };
    };
  };
}
