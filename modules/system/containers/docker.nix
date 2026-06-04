{
  config,
  lib,
  ...
}:
let
  cfg = config.my.system.virtualisation;
in
{
  options.my.system.virtualisation = {
    enable = lib.mkEnableOption "system virtualization and container support";

    # Optional MetaTrader 5 container
    mt5.enable = lib.mkEnableOption "MetaTrader 5 headless container via Docker";

    # Optional 9router container
    "9router".enable = lib.mkEnableOption "9router container via Docker";
  };

  config = lib.mkIf cfg.enable {
    # Add docker group only to users with docker feature enabled
    users.users = lib.mapAttrs (name: _: { extraGroups = [ "docker" ]; }) (
      lib.filterAttrs (name: userCfg: userCfg.userFeatures.docker or false) config.my.users
    );

    programs.virt-manager.enable = true;

    systemd.services = {
      libvirtd.serviceConfig = {
        TimeoutStopSec = "5s";
        TimeoutStartSec = "5s";
      };
    };

    # === Konfigurasi Virtualisasi & Kontainer ===
    virtualisation = {
      docker = {
        enable = true;
        enableOnBoot = false;
        daemon.settings = {
          "data-root" = "/mnt/data_btrfs/docker";
        };
      };

      libvirtd = {
        enable = true;
        onBoot = "ignore";
      };

      oci-containers = {
        backend = "docker";

        containers = {
          # === Integrasi MetaTrader 5 Headless ===
          mt5-headless = lib.mkIf cfg.mt5.enable {
            image = "gmag11/metatrader5_vnc:latest";

            # Port mapping for noVNC web interface
            ports = [
              "8443:6901" # Akses Web GUI KasmVNC
              "8001:8001" # mt5linux Python API bridge for external bots
            ];

            # Persist profile data, EAs, dan signals on the Btrfs partition
            volumes = [
              "/mnt/data_btrfs/mt5-data:/config"
            ];

            environment = {
              VNC_PASSWORD = "123456"; # Ubah sesuai preferensi keamanan Anda
            };
          };

          # === Integrasi 9router ===
          "9router" = lib.mkIf cfg."9router".enable {
            image = "ghcr.io/decolua/9router:latest";

            # Mapping port
            ports = [
              "127.0.0.1:20128:20128" # Mengikat ke localhost demi keamanan
            ];

            # Petakan volume ke direktori persisten agar state tidak hangus oleh impermanence
            volumes = [
              "/var/lib/9router/data:/app/data"
            ];

            # Konfigurasi environment
            environment = {
              NODE_ENV = "production";
            };
          };
        };
      };
    };
  };
}
