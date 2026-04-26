{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:

let
  cfg = config.my.user.services.rclone;
  rcloneRemote = "SemuaDrive";
  mountPoint = "${config.home.homeDirectory}/CloudStorage";
in
{
  options.my.user.services.rclone = {
    enable = selfLib.mkBoolOpt false "rclone mount service";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.rclone ];

    systemd.user.services.rclone-mount = {
      Unit = {
        Description = "Mount Rclone Remote (${rcloneRemote})";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };

      Service = {
        Type = "notify";
        ExecStartPre = [
          "-${pkgs.fuse3}/bin/fusermount3 -uz ${mountPoint}"
          "${pkgs.coreutils}/bin/mkdir -p ${mountPoint}"
          "${pkgs.coreutils}/bin/mkdir -p ${config.home.homeDirectory}/.config/rclone"
          "${pkgs.coreutils}/bin/cp /run/secrets/rclone.conf ${config.home.homeDirectory}/.config/rclone/rclone.conf"
          "${pkgs.coreutils}/bin/chmod 600 ${config.home.homeDirectory}/.config/rclone/rclone.conf"
        ];
        ExecStart = ''
          ${pkgs.rclone}/bin/rclone mount "${rcloneRemote}:" "${mountPoint}" \
            --config "${config.home.homeDirectory}/.config/rclone/rclone.conf" \
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
        # Opsi Cache Warming (Pemanasan Cache) agar akses pertama instan
        ExecStartPost = "-${pkgs.bash}/bin/bash -c 'sleep 5 && ${pkgs.findutils}/bin/find ${mountPoint} -maxdepth 2 > /dev/null 2>&1'";

        # Konsistensi fuse3 (sebelumnya Anda menggunakan fuse biasa di sini)
        ExecStop = "-${pkgs.fuse3}/bin/fusermount3 -uz ${mountPoint}";
        Restart = "on-failure";
        RestartSec = "10s";
        Environment = [ "PATH=/run/wrappers/bin:$PATH" ];
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
