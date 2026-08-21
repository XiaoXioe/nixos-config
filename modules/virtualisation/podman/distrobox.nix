{
  config,
  lib,
  pkgs,
  distroboxPruneScript,
  ...
}:

let
  cfg = config.my.virtualisation.podman;
  distroboxHelper = import ../../_lib/modules/distrobox-helper { inherit lib; };

  activeRegistries = builtins.attrValues (config.my._distroboxRegistry or { });
  mergedContainerMap = distroboxHelper.mergeDistroboxContainers activeRegistries;
  mergedDistroboxContainers = distroboxHelper.mkDistroboxContainers {
    ctx = {
      distroboxCfg = mergedContainerMap;
    };
    useDistrobox = _cId: true;
  };

  distroboxSyncScript = distroboxHelper.mkDistroboxSyncScript {
    inherit pkgs mergedContainerMap mergedDistroboxContainers;
  };
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
    enableSystemdUnit = false; # Non-blocking rebuild: hindari freeze saat nixos-rebuild switch
    containers = mergedDistroboxContainers;
    settings = {
      container_image_default = lib.mkDefault cfg.defaultDistroboxImage;
      container_generate_entry = lib.mkDefault 0;
    };
  };

  systemd.user.services.distrobox-home-manager = {
    Unit = {
      Description = "Non-blocking background Distrobox container assemble and package synchronization";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.writeShellScript "distrobox-home-manager-start" ''
        set -euo pipefail

        # Inisialisasi container deklaratif di background jika belum dibuat
        if [ -f "$HOME/.config/distrobox/containers.ini" ]; then
          echo "==> [distrobox-service] Assembling containers from containers.ini..."
          ${pkgs.distrobox}/bin/distrobox assemble create --file "$HOME/.config/distrobox/containers.ini" || true
        elif [ -f "$HOME/.config/distrobox/distrobox.ini" ]; then
          echo "==> [distrobox-service] Assembling containers from distrobox.ini..."
          ${pkgs.distrobox}/bin/distrobox assemble create --file "$HOME/.config/distrobox/distrobox.ini" || true
        fi

        echo "==> [distrobox-service] Synchronizing Distrobox container packages & hooks..."
        ${distroboxSyncScript}/bin/distrobox-sync || true

        ${lib.optionalString cfg.pruneOrphanContainers ''
          echo "==> [distrobox-service] Pruning orphan containers..."
          ${distroboxPruneScript}/bin/distrobox-prune || true
        ''}
      ''}";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
