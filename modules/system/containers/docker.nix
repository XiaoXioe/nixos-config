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
    # Menambahkan opsi khusus untuk trading bot agar tetap modular
    mt5.enable = selfLib.mkBoolOpt false "MetaTrader 5 headless container via Docker";
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

    # === Integrasi MetaTrader 5 Headless ===
    virtualisation.oci-containers = lib.mkIf cfg.mt5.enable {
      backend = "docker";

      containers.mt5-headless = {
        image = "gmag11/metatrader5_vnc:latest";

        # Mapping port untuk antarmuka web noVNC
        ports = [
          "8443:6901" # Akses Web GUI KasmVNC
          "8001:8001" # Akses mt5linux (Python API Bridge) untuk bot eksternal
        ];

        # Menyimpan data profil, EA, dan sinyal secara persisten di partisi Btrfs Anda
        volumes = [
          "/mnt/data_btrfs/mt5-data:/config"
        ];

        environment = {
          VNC_PASSWORD = "123456"; # Ubah sesuai preferensi keamanan Anda
        };
      };
    };
  };
}
