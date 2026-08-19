{
  config,
  lib,
  selfLib,
  pkgs,
  ...
}:
selfLib.mkModule {
  name = "virtualisation.podman";
  description = "Podman OCI container backend and Distrobox container engine configuration";

  options = {
    defaultDistroboxImage = lib.mkOption {
      type = lib.types.str;
      default = "docker.io/library/debian:testing";
      description = "Single source of truth for the default base OCI image used by Distrobox containers across modules.";
    };

    autoUpdate = {
      enable = lib.mkEnableOption "automatic periodic updates for Distrobox containers";
      onCalendar = lib.mkOption {
        type = lib.types.str;
        default = "weekly";
        description = "Systemd OnCalendar schedule expression for Distrobox container auto-updates.";
      };
    };

    pruneOrphanContainers = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Automatically delete unmanaged / orphan Distrobox containers that are no longer declared in NixOS configuration.";
    };
  };

  nixosConfig =
    let
      cfg = config.my.virtualisation.podman;
      declaredContainers = builtins.attrNames (
        config.home-manager.users.${config.my.user.name}.programs.distrobox.containers or { }
      );

      distroboxPruneScript = pkgs.writeShellScriptBin "distrobox-prune" ''
        set -euo pipefail
        declared_containers=( ${lib.concatStringsSep " " (map (c: "\"${c}\"") declaredContainers)} )

        echo "==> Active declared Distrobox containers: ''${declared_containers[*]:-(none)}"

        existing_containers=$(${pkgs.distrobox}/bin/distrobox list --no-color 2>/dev/null | awk -F'|' 'NR>1 {gsub(/^[ \t]+|[ \t]+$/, "", $2); if ($2 != "") print $2}' || true)

        if [ -z "$existing_containers" ]; then
          echo "No Distrobox containers found."
          exit 0
        fi

        for c in $existing_containers; do
          keep=false
          for d in "''${declared_containers[@]}"; do
            if [ "$c" = "$d" ]; then
              keep=true
              break
            fi
          done
          if [ "$keep" = false ]; then
            echo "==> Pruning unmanaged/orphan Distrobox container: $c"
            ${pkgs.distrobox}/bin/distrobox rm -f "$c" 2>/dev/null || true
          fi
        done
      '';
    in
    {
      # Btrfs NoCoW persistence for Podman container layers
      my.services.storage.btrfs-nocow-migration.nocowDirectories = [
        "${config.my.dataPath}/podman"
      ];

      # Native Podman virtualisation
      virtualisation.podman = {
        enable = true;
        dockerCompat = lib.mkDefault true;
      };

      # System packages for Distrobox runtime
      environment.systemPackages = [
        pkgs.distrobox
        distroboxPruneScript
      ];

      systemd = {
        # Dedicated tmpfiles persistence rules for Podman data
        tmpfiles.rules = [
          "d ${config.my.dataPath}/podman 0755 ${config.my.user.name} users - -"
          "d ${config.my.dataPath}/podman/containers 0755 ${config.my.user.name} users - -"
          "d /home/${config.my.user.name}/.local 0755 ${config.my.user.name} users - -"
          "d /home/${config.my.user.name}/.local/share 0755 ${config.my.user.name} users - -"
          "L+ /home/${config.my.user.name}/.local/share/containers - - - - ${config.my.dataPath}/podman/containers"
        ];

        user = {
          # Automatic prune service for unmanaged Distrobox containers at login/session start
          services.distrobox-prune-orphans = lib.mkIf cfg.pruneOrphanContainers {
            description = "Automatically delete unmanaged / orphan Distrobox containers";
            wantedBy = [ "default.target" ];
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${distroboxPruneScript}/bin/distrobox-prune";
            };
          };

          # Periodic auto-update systemd user service & timer
          services.distrobox-autoupdate = lib.mkIf cfg.autoUpdate.enable {
            description = "Auto-upgrade running Distrobox containers via debdelta / package manager";
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${pkgs.writeShellScript "distrobox-autoupdate" ''
                set -euo pipefail
                echo "==> Upgrading Distrobox containers..."
                ${pkgs.distrobox}/bin/distrobox upgrade --all
                ${lib.optionalString cfg.pruneOrphanContainers ''
                  echo "==> Pruning orphan containers..."
                  ${distroboxPruneScript}/bin/distrobox-prune
                ''}
              ''}";
            };
          };

          timers.distrobox-autoupdate = lib.mkIf cfg.autoUpdate.enable {
            wantedBy = [ "timers.target" ];
            timerConfig = {
              OnCalendar = cfg.autoUpdate.onCalendar;
              Persistent = true;
            };
          };
        };
      };
    };

  hmConfig =
    hmOpts:
    let
      cfg = config.my.virtualisation.podman;
      declaredContainers = builtins.attrNames (hmOpts.config.programs.distrobox.containers or { });

      distroboxPruneScript = pkgs.writeShellScriptBin "distrobox-prune" ''
        set -euo pipefail
        declared_containers=( ${lib.concatStringsSep " " (map (c: "\"${c}\"") declaredContainers)} )

        echo "==> Active declared Distrobox containers: ''${declared_containers[*]:-(none)}"

        existing_containers=$(${pkgs.distrobox}/bin/distrobox list --no-color 2>/dev/null | awk -F'|' 'NR>1 {gsub(/^[ \t]+|[ \t]+$/, "", $2); if ($2 != "") print $2}' || true)

        if [ -z "$existing_containers" ]; then
          echo "No Distrobox containers found."
          exit 0
        fi

        for c in $existing_containers; do
          keep=false
          for d in "''${declared_containers[@]}"; do
            if [ "$c" = "$d" ]; then
              keep=true
              break
            fi
          done
          if [ "$keep" = false ]; then
            echo "==> Pruning unmanaged/orphan Distrobox container: $c"
            ${pkgs.distrobox}/bin/distrobox rm -f "$c" 2>/dev/null || true
          fi
        done
      '';
    in
    {
      programs.distrobox.settings = {
        container_image_default = lib.mkDefault cfg.defaultDistroboxImage;
        container_generate_entry = lib.mkDefault 0;
      };

      systemd.user.services.distrobox-home-manager = {
        Unit = {
          After = [ "network-online.target" ];
          Wants = [ "network-online.target" ];
        };
        Service = {
          Restart = "on-failure";
          RestartSec = "30s";
        }
        // (lib.optionalAttrs cfg.pruneOrphanContainers {
          ExecStartPost = "${distroboxPruneScript}/bin/distrobox-prune";
        });
      };
    };
}
