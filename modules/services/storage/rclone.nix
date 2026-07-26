{
  config,
  pkgs,
  inputs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "services.storage.rclone";
  description = "rclone mount service";

  nixosConfig = {
    programs.fuse.userAllowOther = true;

    sops.secrets."rclone.conf" = {
      format = "binary";
      sopsFile = selfLib.secretBinary "rclone.enc.conf";
      owner = config.my.user.name;
      mode = "0400";
    };
  };

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
          "X-SwitchMethod" = "keep-old";
        };
        Service = {
          Type = "simple";
          ExecStartPre = [
            "-${pkgs.bash}/bin/bash -c '/run/wrappers/bin/fusermount3 -uz ${mountPoint} > /dev/null 2>&1 || true'"
            "${pkgs.coreutils}/bin/mkdir -p ${mountPoint}"
            "${pkgs.coreutils}/bin/mkdir -p ${hmOpts.config.home.homeDirectory}/.config/rclone"
            "${pkgs.coreutils}/bin/cp ${hmOpts.osConfig.sops.secrets."rclone.conf".path} %t/rclone.conf"
            "${pkgs.coreutils}/bin/chmod 600 %t/rclone.conf"
          ];
          ExecStart = "${pkgs.writeShellScript "rclone-mount" ''
            # Wait for SOCKS5 proxy port 40000 and verify actual internet connectivity
            for i in {1..30}; do
              if ${pkgs.curl}/bin/curl -s --max-time 3 -o /dev/null --proxy socks5h://127.0.0.1:40000 https://www.google.com; then
                break
              fi
              ${pkgs.coreutils}/bin/sleep 2
            done

            exec ${pkgs.rclone}/bin/rclone mount "${rcloneRemote}:" "${mountPoint}" \
              --config "$XDG_RUNTIME_DIR/rclone.conf" \
              --rc \
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
            "HTTP_PROXY=socks5h://127.0.0.1:40000"
            "HTTPS_PROXY=socks5h://127.0.0.1:40000"
            "ALL_PROXY=socks5h://127.0.0.1:40000"
          ];
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };
    };
}
