{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:

let
  rcloneRemote = "semua-drive";
in

selfLib.mkModule {
  name = "services.storage.rclone";
  description = "Rclone FUSE Cloud Storage Mount";

  nixosConfig = {
    sops.secrets = builtins.listToAttrs [
      (selfLib.secrets.mkSecret {
        key = "rclone.conf";
        sopsFile = selfLib.secretBinary "storage/rclone.enc.conf";
        format = "binary";
        owner = config.my.user.name;
        mode = "0444";
      })
    ];

    programs.fuse.userAllowOther = true;
  };

  hmConfig =
    hmOpts:
    let
      mountPoint = "${hmOpts.config.home.homeDirectory}/CloudStorage";
      rcPort = 5572;
    in
    {
      systemd.user.services.rclone-mount = {
        Unit = {
          Description = "Mount Rclone FUSE Cloud Storage (${rcloneRemote})";
          After = [ "network-online.target" ];
          Wants = [ "network-online.target" ];
          "X-SwitchMethod" = "keep-old";
        };
        Service = {
          Type = "simple";
          NotifyAccess = "none";
          ExecStartPre = [
            "-/run/wrappers/bin/fusermount3 -u ${mountPoint}"
            "${pkgs.coreutils}/bin/mkdir -p ${mountPoint}"
            "${selfLib.mkApp pkgs "rclone-copy-config" ''
              cp ${hmOpts.osConfig.sops.secrets."rclone.conf".path} "$XDG_RUNTIME_DIR/rclone.conf"
              chmod 600 "$XDG_RUNTIME_DIR/rclone.conf"
            '' [ pkgs.coreutils ]}"
          ];
          ExecStart = "${selfLib.mkApp pkgs "rclone-mount-start"
            ''
              set -euo pipefail
              export PATH="/run/wrappers/bin:$PATH"
              unset NOTIFY_SOCKET

              ${selfLib.mkWarpWaitScript pkgs "rclone-wait-proxy"}

              exec rclone mount "${rcloneRemote}:" "${mountPoint}" \
                --config "$XDG_RUNTIME_DIR/rclone.conf" \
                --rc \
                --rc-addr "127.0.0.1:${toString rcPort}" \
                --rc-no-auth \
                --allow-other \
                --vfs-cache-mode full \
                --vfs-cache-max-age 24h \
                --vfs-cache-max-size 5G \
                --vfs-write-back 5s \
                --dir-cache-time 1000h \
                --attr-timeout 1000h \
                --poll-interval 15s \
                --vfs-read-chunk-size 32M \
                --vfs-read-chunk-size-limit 1G \
                --buffer-size 64M \
                --no-checksum \
                --no-modtime
            ''
            [
              pkgs.rclone
              pkgs.fuse3
              pkgs.coreutils
            ]
          }";
          ExecStop = "/run/wrappers/bin/fusermount3 -u ${mountPoint}";
          Restart = "on-failure";
          RestartSec = "10s";
          Environment = lib.mapAttrsToList (n: v: "${n}=${v}") selfLib.warpProxyEnv;
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };
    };
}
