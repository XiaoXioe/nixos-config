{
  config,
  lib,
  pkgs,
  selfLib,
  ...
}:

let
  cfg = config.my.services.btrfs-config;
in
{
  options.my.services.btrfs-config = {
    enable = selfLib.mkBoolOpt false "Btrfs configuration";
  };

  config = lib.mkIf cfg.enable {

    # Memaksa Btrfs Quota mati secara deklaratif setiap kali boot
    systemd.services.btrfs-quota-disable = {
      description = "Ensure Btrfs quota is disabled for / and /home";
      wantedBy = [ "multi-user.target" ];
      after = [ "local-fs.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      # Gunakan 'script' agar dieksekusi dengan Bash (|| true akan berfungsi normal)
      script = ''
        ${pkgs.btrfs-progs}/bin/btrfs quota disable / || true
        ${pkgs.btrfs-progs}/bin/btrfs quota disable /home || true
      '';
    };
  };
}
