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
        # Ubah ExecStartPre menjadi bentuk List
        ExecStartPre = [
          "${pkgs.coreutils}/bin/mkdir -p ${mountPoint}"
          # 1. Buat direktori config untuk rclone jika belum ada
          "${pkgs.coreutils}/bin/mkdir -p ${config.home.homeDirectory}/.config/rclone"
          # 2. Salin config dari sops ke direktori user agar rclone bisa menulis ulang tokennya
          "${pkgs.coreutils}/bin/cp /run/secrets/rclone.conf ${config.home.homeDirectory}/.config/rclone/rclone.conf"
          # 3. Pastikan user memiliki hak akses baca dan tulis (Read/Write)
          "${pkgs.coreutils}/bin/chmod 600 ${config.home.homeDirectory}/.config/rclone/rclone.conf"
        ];
        ExecStart = ''
          ${pkgs.rclone}/bin/rclone mount "${rcloneRemote}:" "${mountPoint}" \
            --vfs-cache-mode full \
            --config "${config.home.homeDirectory}/.config/rclone/rclone.conf" \
            --vfs-cache-max-age 24h \
            --vfs-read-chunk-size 32M \
            --vfs-read-chunk-size-limit 1G \
            --buffer-size 64M \
            --no-modtime \
            --drive-use-trash \
            --stats=15m \
            --checkers=16 \
            --transfers=8 \
            --log-file="${config.home.homeDirectory}/.config/rclone/rclone.log" \
            --log-level INFO
        '';
        ExecStop = "${pkgs.fuse}/bin/fusermount -uz ${mountPoint}";
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
