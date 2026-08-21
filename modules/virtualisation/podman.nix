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
                echo "==> Upgrading Distrobox containers (official packages)..."
                ${pkgs.distrobox}/bin/distrobox upgrade --all || true

                # Check and update AUR packages on Arch Linux containers
                existing_containers=$(${pkgs.distrobox}/bin/distrobox list --no-color 2>/dev/null | awk -F'|' 'NR>1 {gsub(/^[ \t]+|[ \t]+$/, "", $2); if ($2 != "") print $2}' || true)
                for c in $existing_containers; do
                  if ${pkgs.distrobox}/bin/distrobox enter "$c" -- sh -c "command -v pacman >/dev/null 2>&1"; then
                    echo "==> [distrobox-autoupdate] Checking AUR updates for container '$c'..."
                    ${pkgs.distrobox}/bin/distrobox enter "$c" -- bash -c '
                      _buser=$(id -un 1000 2>/dev/null || whoami)
                      aur_pkgs=$(pacman -Qm -q 2>/dev/null || true)
                      if [ -n "$aur_pkgs" ]; then
                        for pkg in $aur_pkgs; do
                          echo "==> [distrobox-autoupdate] Checking AUR package: $pkg..."
                          _aur_tmp=$(mktemp -d /tmp/aur-update-"$pkg"-XXXXXX)
                          chown -R "$_buser" "$_aur_tmp"
                          if sudo -u "$_buser" git clone --depth 1 "https://aur.archlinux.org/$pkg.git" "$_aur_tmp" 2>/dev/null; then
                            (cd "$_aur_tmp" && sudo -u "$_buser" makepkg -si --noconfirm --skippgpcheck --needed) || true
                          fi
                          rm -rf "$_aur_tmp"
                        done
                      fi
                    ' || true
                  fi
                done

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
      activeRegistries = builtins.attrValues (config.my._distroboxRegistry or { });
      distroboxHelper = import ../_lib/modules/distrobox-helper { inherit lib; };
      distrosModule = import ../_lib/modules/distrobox-helper/distros.nix { inherit lib; };
      mergedContainerMap = distroboxHelper.mergeDistroboxContainers activeRegistries;
      mergedDistroboxContainers = distroboxHelper.mkDistroboxContainers {
        ctx = {
          distroboxCfg = mergedContainerMap;
        };
        # useDistrobox is the partially-applied form: cId -> bool
        useDistrobox = _cId: true;
      };
      distroboxSyncScript = pkgs.writeShellScriptBin "distrobox-sync" ''
        set -euo pipefail

        ${lib.concatStringsSep "\n" (
          lib.mapAttrsToList (
            cId: cDef:
            let
              # ──
              rawCfg = mergedContainerMap.${cId};
              targetDistro =
                if rawCfg.distro != "auto" then rawCfg.distro else distrosModule.detectDistro rawCfg.image;
              # getDistroInstallCmd returns { check, cmd } or null (for custom/unknown).
              installInfo = distrosModule.getDistroInstallCmd { distro = targetDistro; };

              hasPkgs = cDef ? additional_packages && cDef.additional_packages != "" && installInfo != null;
              hasPreHooks = cDef ? pre_init_hooks && cDef.pre_init_hooks != [ ];
              hasHooks = cDef ? init_hooks && cDef.init_hooks != [ ];

              preHooksCmd = lib.optionalString hasPreHooks (
                lib.concatStringsSep "\n" (map (h: "  " + h) cDef.pre_init_hooks)
              );
              preHooksScript = pkgs.writeShellScript "distrobox-pre-hooks-${cId}" ''
                set -euo pipefail
                ${preHooksCmd}
              '';

              hooksCmd = lib.optionalString hasHooks (
                lib.concatStringsSep "\n" (map (h: "  " + h) cDef.init_hooks)
              );
              hooksScript = pkgs.writeShellScript "distrobox-hooks-${cId}" ''
                set -euo pipefail
                ${hooksCmd}
              '';
            in
            ''
              echo "==> [distrobox-sync] Synchronizing container: ${cId} (${targetDistro})"
              if ${pkgs.distrobox}/bin/distrobox enter "${cId}" -- true 2>/dev/null; then
                ${lib.optionalString hasPreHooks ''
                  echo "==> [distrobox-sync] Running pre-init hooks for ${cId}..."
                  ${pkgs.distrobox}/bin/distrobox enter "${cId}" -- ${preHooksScript} || true
                ''}
                ${lib.optionalString hasPkgs ''
                  if ${pkgs.distrobox}/bin/distrobox enter "${cId}" -- sh -c "command -v ${installInfo.check} >/dev/null 2>&1"; then
                    echo "==> [distrobox-sync] Installing packages for ${cId} (${installInfo.cmd})..."
                    ${pkgs.distrobox}/bin/distrobox enter "${cId}" -- sudo ${installInfo.cmd} ${cDef.additional_packages} || true
                  fi
                ''}
                ${lib.optionalString hasHooks ''
                  echo "==> [distrobox-sync] Running init hooks for ${cId}..."
                  ${pkgs.distrobox}/bin/distrobox enter "${cId}" -- ${hooksScript} || true
                ''}
              fi
            ''
          ) mergedDistroboxContainers
        )}
      '';
    in
    {
      home.packages = [
        distroboxSyncScript
      ];

      # Auto-authorize host display for container GUI applications
      home.file.".distroboxrc" = {
        text = ''
          # Auto-authorize host display for container GUI applications (X11 / XWayland fallback)
          if command -v ${pkgs.xhost}/bin/xhost >/dev/null 2>&1; then
            ${pkgs.xhost}/bin/xhost +si:localuser:$USER >/dev/null 2>&1 || true
          fi
        '';
      };

      programs.distrobox = {
        enable = true;
        enableSystemdUnit = false;
        containers = mergedDistroboxContainers;
        settings = {
          container_image_default = lib.mkDefault cfg.defaultDistroboxImage;
          container_generate_entry = lib.mkDefault 0;
        };
      };

      systemd.user.services.distrobox-home-manager = {
        Unit = {
          After = [ "network-online.target" ];
          Wants = [ "network-online.target" ];
        };
        Service = {
          Restart = "on-failure";
          RestartSec = "30s";
          ExecStartPost = "${pkgs.writeShellScript "distrobox-home-manager-post" ''
            set -euo pipefail
            echo "==> Synchronizing Distrobox container packages & hooks..."
            ${distroboxSyncScript}/bin/distrobox-sync
            ${lib.optionalString cfg.pruneOrphanContainers ''
              echo "==> Pruning orphan containers..."
              ${distroboxPruneScript}/bin/distrobox-prune
            ''}
          ''}";
        };
      };
    };
}
