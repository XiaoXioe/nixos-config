{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "services.rclone";
  description = "rclone mount service";

  hmConfig =
    { config, osConfig, ... }:
    let
      rcloneRemote = "SemuaDrive";
      mountPoint = "${config.home.homeDirectory}/CloudStorage";
    in
    {
      home.packages = [ pkgs.rclone ];
      systemd.user.services.rclone-mount = {
        Unit = {
          Description = "Mount Rclone Remote (${rcloneRemote})";
          After = [ "network-online.target" ];
          Wants = [ "network-online.target" ];
        };
        Service = {
          Type = "simple";
          ExecStartPre = [
            "-${pkgs.bash}/bin/bash -c '${pkgs.fuse3}/bin/fusermount3 -uz ${mountPoint} > /dev/null 2>&1 || true'"
            "${pkgs.coreutils}/bin/mkdir -p ${mountPoint}"
            "${pkgs.coreutils}/bin/mkdir -p ${config.home.homeDirectory}/.config/rclone"
          ];
          ExecStart = ''
            ${pkgs.rclone}/bin/rclone mount "${rcloneRemote}:" "${mountPoint}" \
              --config "${osConfig.sops.secrets."rclone.conf".path}" \
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
              --no-modtime \
              --drive-use-trash \
              --transfers=4 \
              --vfs-fast-fingerprint \
              --no-checksum \
              --drive-pacer-min-sleep=10ms \
              --log-file="${config.home.homeDirectory}/.config/rclone/rclone.log" \
              --log-level INFO
          '';
          ExecStartPost = "-${pkgs.bash}/bin/bash -c '(${pkgs.coreutils}/bin/sleep 10 && ${pkgs.findutils}/bin/find ${mountPoint} -maxdepth 2 > /dev/null 2>&1) &'";
          Restart = "on-failure";
          RestartSec = "10s";
          TimeoutSec = "5m";
          Environment = [ "PATH=/run/wrappers/bin:$PATH" ];
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };
    };
}
