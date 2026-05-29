{
  config,
  lib,
  ...
}:
let
  cfg = config.my.system.virtualization;
in
{
  options.my.system.virtualization = {
    enable = lib.mkEnableOption "system virtualization and container support";
    # Optional MetaTrader 5 container
    mt5.enable = lib.mkEnableOption "MetaTrader 5 headless container via Docker";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.docker = {
      enable = true;
      enableOnBoot = false;
      daemon.settings = {
        "data-root" = "/mnt/data_btrfs/docker";
      };
    };

    # Add docker group only to users with docker feature enabled
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

        # Port mapping for noVNC web interface
        ports = [
          "8443:6901" # Akses Web GUI KasmVNC
          "8001:8001" # mt5linux Python API bridge for external bots
        ];

        # Persist profile data, EAs, and signals on the Btrfs partition
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
