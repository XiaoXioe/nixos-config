{
  config,
  lib,
  selfLib,
  pkgs,
  ...
}:
selfLib.mkModule {
  name = "virtualisation.docker";
  options = {
    mt5.enable = lib.mkEnableOption "MetaTrader 5 headless container via Docker";
    "9router".enable = lib.mkEnableOption "9router container via Docker";
    autoUpdate.enable = lib.mkEnableOption "automatic updates for all Docker containers via Watchtower";
  };

  nixosConfig =
    let
      cfg = config.my.virtualisation.docker;
    in
    {
      users.users.${config.my.user.name}.extraGroups = [ "docker" ];

      environment.variables = {

        # 9Router AI gateway
        NINEROUTER_URL = "http://localhost:20128";
      };



      systemd.services.docker-autoupdate = lib.mkIf cfg.autoUpdate.enable {
        description = "Auto-update all running Docker containers";
        path = [
          pkgs.docker
          pkgs.systemd
          pkgs.coreutils
        ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "docker-autoupdate" ''
            set -euo pipefail

            # Get list of running docker container names
            containers=$(docker ps --format '{{.Names}}')

            for container in $containers; do
              # Get image name used by the container
              image=$(docker inspect --format '{{.Config.Image}}' "$container")

              echo "Checking updates for $container ($image)..."

              # Store the old image ID
              old_image_id=$(docker image inspect --format '{{.Id}}' "$image" 2>/dev/null || echo "")

              # Pull the latest image
              if docker pull "$image"; then
                # Get the new image ID
                new_image_id=$(docker image inspect --format '{{.Id}}' "$image" 2>/dev/null || echo "")

                # If the image was updated, restart the systemd service for the container
                if [ "$old_image_id" != "$new_image_id" ]; then
                  echo "Image updated for $container. Restarting service docker-$container.service..."
                  if systemctl is-active --quiet "docker-$container.service"; then
                    systemctl restart "docker-$container.service"
                  else
                    echo "Service docker-$container.service is not active, skipping restart."
                  fi
                else
                  echo "Image is already up-to-date for $container."
                fi
              else
                echo "Failed to pull image $image"
              fi
            done
          '';
        };
      };

      systemd.timers.docker-autoupdate = lib.mkIf cfg.autoUpdate.enable {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "5m";
          OnUnitActiveSec = "4h";
          Unit = "docker-autoupdate.service";
        };
      };

      virtualisation = {
        docker = {
          enable = true;
          enableOnBoot = true;
          daemon.settings = {
            "data-root" = "/mnt/data_btrfs/docker";
          };
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
              environmentFiles = lib.optional cfg.mt5.enable config.sops.secrets."mt5-vnc-env".path;
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

          };
        };
      };
    };
}
