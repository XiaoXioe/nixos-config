{
  config,
  lib,
  selfLib,
  ...
}:
selfLib.mkModule {
  name = "virtualisation.docker";
  options = {
    mt5.enable = lib.mkEnableOption "MetaTrader 5 headless container via Docker";
    "9router".enable = lib.mkEnableOption "9router container via Docker";
    autoUpdate = lib.mkEnableOption "automatic updates for all Docker containers via Watchtower";
  };

  nixosConfig =
    let
      cfg = config.my.virtualisation.docker;
    in
    {
      users.users = lib.mapAttrs (_name: _: { extraGroups = [ "docker" ]; }) (
        lib.filterAttrs (_name: userCfg: userCfg.userFeatures.virtualisation.docker or false) config.my.users
      );

      programs.virt-manager.enable = true;

      systemd.services.libvirtd.serviceConfig = {
        TimeoutStopSec = "5s";
        TimeoutStartSec = "5s";
      };

      virtualisation = {
        docker = {
          enable = true;
          enableOnBoot = true;
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
            mt5-headless = lib.mkIf cfg.mt5.enable {
              image = "gmag11/metatrader5_vnc:latest";
              ports = [
                "8443:6901"
                "8001:8001"
              ];
              volumes = [ "/mnt/data_btrfs/mt5-data:/config" ];
              environment = {
                VNC_PASSWORD = "123456";
              };
            };

            "9router" = lib.mkIf cfg."9router".enable {
              image = "ghcr.io/decolua/9router:latest";
              ports = [ "127.0.0.1:20128:20128" ];
              volumes = [ "/var/lib/9router/data:/app/data" ];
              environment = {
                NODE_ENV = "production";
                PORT = "20128";
                HOSTNAME = "0.0.0.0";
                DATA_DIR = "/app/data";
                BASE_URL = "http://localhost:20128";
                NEXT_PUBLIC_BASE_URL = "http://localhost:20128";
                REQUIRE_API_KEY = "true";
                AUTH_COOKIE_SECURE = "false";
                ENABLE_REQUEST_LOGS = "false";
                OBSERVABILITY_ENABLED = "true";
              };
              environmentFiles = lib.optional cfg."9router".enable config.sops.secrets."9router-env".path;
            };

            watchtower = lib.mkIf cfg.autoUpdate {
              image = "containrrr/watchtower:latest";
              volumes = [ "/var/run/docker.sock:/var/run/docker.sock" ];
              environment = {
                DOCKER_API_VERSION = "1.40";
                WATCHTOWER_CLEANUP = "true";
                WATCHTOWER_POLL_INTERVAL = "86400";
                WATCHTOWER_INCLUDE_STOPPED = "true";
                WATCHTOWER_REVIVE_STOPPED = "false";
              };
            };
          };
        };
      };
    };
}
