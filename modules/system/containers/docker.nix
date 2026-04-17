{
  config,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.system.virtualization;
in
{
  options.my.system.virtualization = {
    enable = selfLib.mkBoolOpt false "system virtualization and container support";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.docker = {
      enable = true;
      enableOnBoot = false;
      daemon.settings = {
        "data-root" = "/mnt/data_btrfs/docker";
      };
    };

    # Menambahkan grup docker hanya kepada user yang memiliki fitur docker = true
    users.users = lib.mapAttrs (name: _: { extraGroups = [ "docker" ]; }) (
      lib.filterAttrs (name: userCfg: userCfg.userFeatures.docker or false) config.my.users
    );

    programs.virt-manager.enable = true;
    virtualisation.libvirtd = {
      enable = true;
      onBoot = "ignore"; # atau "disable" tergantung versi nixpkgs
    };
    systemd.services.libvirtd.serviceConfig.TimeoutStartSec = "5s";
    systemd.services.libvirtd.serviceConfig.TimeoutStopSec = "5s";
  };
}
