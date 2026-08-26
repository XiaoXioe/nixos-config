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
  resticPkg = selfLib.fetchCachePinned "restic";
  rclonePkg = selfLib.fetchCachePinned "rclone";

  resticFlockWrapper =
    selfLib.mkApp pkgs "restic"
      ''
        exec 9>/run/restic-backup.lock
        flock -x 9
        exec restic "$@"
      ''
      [
        pkgs.util-linux
        resticPkg
      ];
in

selfLib.mkModule {
  name = "services.storage.restic";
  description = "Restic Backup Service via Rclone (Domain-Separated)";

  nixosConfig =
    let
      # Shared exclude list across domains
      commonExcludes = [
        ".cache"
        "venv"
        ".venv"
        "node_modules"
        "dataset"
        "ml"
      ];

      # Helper function untuk membuat konfigurasi backup per domain
      mkBackupConfig =
        {
          name,
          paths,
          onCalendar,
          backupPrepareCommand ? null,
          backupCleanupCommand ? null,
        }:
        {
          services.restic.backups.${name} = {
            repository = resticRepo;
            rcloneConfigFile = config.sops.secrets."rclone.conf".path;
            passwordFile = config.sops.secrets."restic-password".path;
            package = resticFlockWrapper;
            extraOptions = [
              "rclone.timeout=5m"
            ];

            inherit paths;
            exclude = commonExcludes;
            initialize = true;
            extraBackupArgs = [
              "--tag"
              name
              "--no-lock"
            ];

            timerConfig = {
              OnCalendar = onCalendar;
              Persistent = true;
              RandomizedDelaySec = "10m";
            };

            pruneOpts = [
              "--keep-daily 7"
              "--keep-weekly 4"
              "--keep-monthly 6"
            ];
          }
          // (lib.optionalAttrs (backupPrepareCommand != null) { inherit backupPrepareCommand; })
          // (lib.optionalAttrs (backupCleanupCommand != null) { inherit backupCleanupCommand; });

          systemd.services."restic-backups-${name}" = {
            onFailure = [ "status-alert@restic-backups-${name}.service" ];
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
              RCLONE_CONFIG = lib.mkForce "/run/restic-backups-${name}/rclone.conf";
              RESTIC_PROGRESS_FPS = "0.016666";
            }
            // (selfLib.warpProxyEnv config.my.services.networking.cloudflare-warp.port);

            serviceConfig = {
              TimeoutStopSec = "120s";
              KillSignal = "SIGINT";
              ExecStartPre = lib.mkBefore [
                (selfLib.mkWarpWaitScript pkgs config.my.services.networking.cloudflare-warp.port
                  "restic-backups-${name}-wait-proxy"
                )
                "${selfLib.mkApp pkgs "restic-backups-${name}-copy-rclone-config" ''
                  mkdir -p /run/restic-backups-${name}
                  cp ${config.sops.secrets."rclone.conf".path} /run/restic-backups-${name}/rclone.conf
                  chmod 600 /run/restic-backups-${name}/rclone.conf
                '' [ pkgs.coreutils ]}"
                "${selfLib.mkApp pkgs "restic-backups-${name}-auto-unlock"
                  ''
                    export RCLONE_CONFIG="/run/restic-backups-${name}/rclone.conf"
                    ${resticFlockWrapper} -o rclone.timeout=5m -r "${resticRepo}" --password-file "${
                      config.sops.secrets."restic-password".path
                    }" unlock --remove-all || true
                  ''
                  [
                    pkgs.coreutils
                    rclonePkg
                  ]
                }"
              ];
            };
          };
        };

      # Domain 1: Vaultwarden (Setiap 3 jam: 00:00, 03:00, 06:00, dst) - Zero Downtime Online Backup
      vaultwardenBackup = mkBackupConfig {
        name = "vaultwarden";
        paths = [
          "/run/vaultwarden-backup"
        ];
        onCalendar = "00/3:00:00";
        backupPrepareCommand = ''
          ${pkgs.coreutils}/bin/mkdir -p /run/vaultwarden-backup
          ${pkgs.coreutils}/bin/rm -rf /run/vaultwarden-backup/*
          ${pkgs.coreutils}/bin/cp -a /persist/var/lib/vaultwarden/. /run/vaultwarden-backup/
          ${pkgs.sqlite}/bin/sqlite3 /persist/var/lib/vaultwarden/db.sqlite3 ".backup '/run/vaultwarden-backup/db.sqlite3'"
          ${pkgs.coreutils}/bin/rm -f /run/vaultwarden-backup/db.sqlite3-wal /run/vaultwarden-backup/db.sqlite3-shm
        '';
        backupCleanupCommand = "${pkgs.coreutils}/bin/rm -rf /run/vaultwarden-backup";
      };

      # Domain 2: System & Nix Configuration (Setiap 3 jam + offset 15 menit: 00:15, 03:15, dst)
      systemConfigBackup = mkBackupConfig {
        name = "system-config";
        paths = [
          "/var/lib/vnstat"
          "/persist/etc/ssh"
          "/persist/home/${config.my.user.name}/nixos-config"
          "/persist/home/${config.my.user.name}/nix-custompkgs"
          "/persist/home/${config.my.user.name}/nix-custompkg-priv"
          "/persist/home/${config.my.user.name}/nix-mcp"
        ];
        onCalendar = "00/3:15:00";
      };

      # Domain 3: User Personal Data & Files (Setiap 3 jam + offset 30 menit: 00:30, 03:30, dst)
      userDataBackup = mkBackupConfig {
        name = "user-data";
        paths = [
          "/home/${config.my.user.name}/.gemini"
          "/home/${config.my.user.name}/.ssh"
          "/home/${config.my.user.name}/.gnupg"
          "/home/${config.my.user.name}/.thunderbird"
          "/persist/home/${config.my.user.name}/pentest"
          "${config.my.dataPath}/Documents"
          "${config.my.dataPath}/Pictures"
          "${config.my.dataPath}/Music"
          "${config.my.dataPath}/PersistentData"
          "${config.my.dataPath}/backup-cloud"
        ];
        onCalendar = "00/3:30:00";
      };
    in
    lib.mkMerge [
      {
        # Secret declaration for restic password
        sops.secrets."restic-password" = {
          sopsFile = ./secrets.yaml;
          owner = config.my.user.name;
          mode = "0400";
        };

        environment.systemPackages = [
          (pkgs.symlinkJoin {
            name = "rclone-proxy-wrapper";
            paths = [ rclonePkg ];
            buildInputs = [ pkgs.makeWrapper ];
            postBuild =
              let
                proxyEnv = selfLib.warpProxyEnv config.my.services.networking.cloudflare-warp.port;
              in
              ''
                wrapProgram $out/bin/rclone \
                  --set HTTP_PROXY "${proxyEnv.HTTP_PROXY}" \
                  --set HTTPS_PROXY "${proxyEnv.HTTPS_PROXY}" \
                  --set ALL_PROXY "${proxyEnv.ALL_PROXY}"
              '';
          })
        ];
      }
      vaultwardenBackup
      systemConfigBackup
      userDataBackup
    ];

  hmConfig = hmOpts: {
    systemd.user.services.restic-mount = {
      Unit = {
        Description = "Mount Restic Backup Repository (FUSE on-demand)";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
        "X-SwitchMethod" = "keep-old";
        OnFailure = [ "status-alert@restic-mount.service" ];
      };
      Service = {
        Type = "simple";
        ExecStartPre = [
          "-/run/wrappers/bin/fusermount3 -u ${mountPoint}"
          "${pkgs.coreutils}/bin/mkdir -p ${mountPoint}"
        ];
        ExecStart = "${selfLib.mkApp pkgs "restic-mount-start"
          ''
            set -euo pipefail
            export PATH="/run/wrappers/bin:$PATH"

            ${selfLib.mkWarpWaitScript pkgs hmOpts.osConfig.my.services.networking.cloudflare-warp.port
              "restic-mount-wait-proxy"
            }

            export RCLONE_CONFIG="${hmOpts.osConfig.sops.secrets."rclone.conf".path}"
            exec restic mount "${mountPoint}" \
              --repo "${resticRepo}" \
              --password-file "${hmOpts.osConfig.sops.secrets."restic-password".path}"
          ''
          [
            resticPkg
            pkgs.coreutils
          ]
        }";
        ExecStop = "/run/wrappers/bin/fusermount3 -u ${mountPoint}";
        Restart = "on-failure";
        RestartSec = "10s";
        Environment = lib.mapAttrsToList (n: v: "${n}=${v}") (
          selfLib.warpProxyEnv hmOpts.osConfig.my.services.networking.cloudflare-warp.port
        );
      };
    };
  };
}
