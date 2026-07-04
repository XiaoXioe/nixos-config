{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "services.rclone";
  description = "rclone mount service";

  hmConfig =
    hmOpts:
    let
      rcloneRemote = "semua-drive";
      mountPoint = "${hmOpts.config.home.homeDirectory}/CloudStorage";
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
            "-${pkgs.bash}/bin/bash -c '/run/wrappers/bin/fusermount3 -uz ${mountPoint} > /dev/null 2>&1 || true'"
            "${pkgs.coreutils}/bin/mkdir -p ${mountPoint}"
            "${pkgs.coreutils}/bin/mkdir -p ${hmOpts.config.home.homeDirectory}/.config/rclone"
            "${pkgs.coreutils}/bin/cp ${hmOpts.osConfig.sops.secrets."rclone.conf".path} %t/rclone.conf"
            "${pkgs.coreutils}/bin/chmod 600 %t/rclone.conf"
            "${pkgs.bash}/bin/bash -c 'for i in {1..30}; do if echo > /dev/tcp/127.0.0.1/40000; then exit 0; fi; ${pkgs.coreutils}/bin/sleep 1; done; exit 1'"
          ];
          ExecStart = "${pkgs.writeShellScript "rclone-mount" ''
            exec ${pkgs.rclone}/bin/rclone mount "${rcloneRemote}:" "${mountPoint}" \
              --config "$XDG_RUNTIME_DIR/rclone.conf" \
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
              --vfs-fast-fingerprint \
              --no-checksum \
              --drive-pacer-min-sleep=100ms \
              --log-file="${hmOpts.config.home.homeDirectory}/.config/rclone/rclone.log" \
              --log-level INFO
          ''}";
          Restart = "on-failure";
          RestartSec = "10s";
          TimeoutSec = "5m";
          Environment = [
            "PATH=/run/wrappers/bin:$PATH"
            "HTTP_PROXY=socks5://127.0.0.1:40000"
            "HTTPS_PROXY=socks5://127.0.0.1:40000"
            "ALL_PROXY=socks5://127.0.0.1:40000"
          ];
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };
    };
}
