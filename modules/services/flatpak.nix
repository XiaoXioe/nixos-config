{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:

let
  syncFlatpakRepoScript =
    selfLib.mkApp pkgs "sync-flatpak-repo"
      ''
        REPO_DIR="$HOME/CloudStorage/gdrive-union-decrypted/custom-flatpaks/repo"
        RCLONE_MOUNT_POINT="$HOME/CloudStorage"
        RC_URL="http://127.0.0.1:5572"

        echo "==> [sync-flatpak-repo] Checking rclone FUSE mount..."
        if ! mountpoint -q "$RCLONE_MOUNT_POINT"; then
          echo "ERROR: Rclone FUSE mount is not active at $RCLONE_MOUNT_POINT"
          exit 1
        fi

        echo "==> [sync-flatpak-repo] Refreshing Rclone VFS cache via RC API..."
        if curl -s -f -X POST "$RC_URL/vfs/refresh?recursive=true&dir=custom-flatpaks" > /dev/null 2>&1; then
          echo "==> [sync-flatpak-repo] VFS cache refreshed successfully."
        else
          echo "WARNING: Rclone RC endpoint unreachable at $RC_URL/vfs/refresh. Proceeding with filesystem check..."
        fi

        echo "==> [sync-flatpak-repo] Verifying repository path..."
        if [ ! -d "$REPO_DIR" ]; then
          echo "ERROR: Custom Flatpak repository directory not found at $REPO_DIR"
          exit 1
        fi

        echo "==> [sync-flatpak-repo] Triggering non-interactive Flatpak update..."
        flatpak update --system -y || true
        flatpak update --user -y || true

        echo "==> [sync-flatpak-repo] Sync completed successfully."
      ''
      [
        pkgs.coreutils
        pkgs.util-linux
        pkgs.curl
        pkgs.flatpak
      ];
in
selfLib.mkModule {
  name = "services.flatpak";
  description = "Core Flatpak daemon, BTRFS persistent mounts, global overrides, and repository sync service";

  nixosConfig = {
    my.services.storage.btrfs-nocow-migration.nocowDirectories = [
      "${config.my.dataBtrfsPath}/flatpak-userdata"
    ];

    systemd.tmpfiles.rules = [
      "d ${config.my.dataBtrfsPath}/flatpak-userdata 0755 ${config.my.user.name} users - -"
      "d ${config.my.dataBtrfsPath}/flatpak-local 0755 ${config.my.user.name} users - -"
      "d ${config.my.dataBtrfsPath}/containers 0755 ${config.my.user.name} users - -"
      "d /home/${config.my.user.name}/CloudStorage 0755 ${config.my.user.name} users - -"
      "d /home/${config.my.user.name}/.var 0755 ${config.my.user.name} users - -"
      "d /home/${config.my.user.name}/.local 0755 ${config.my.user.name} users - -"
      "d /home/${config.my.user.name}/.local/share 0755 ${config.my.user.name} users - -"
      "L+ /home/${config.my.user.name}/.var/app - - - - ${config.my.dataBtrfsPath}/flatpak-userdata"
      "L+ /home/${config.my.user.name}/.local/share/flatpak - - - - ${config.my.dataBtrfsPath}/flatpak-local"
      "L+ /home/${config.my.user.name}/.local/share/containers - - - - ${config.my.dataBtrfsPath}/containers"
    ];

    services.flatpak = {
      enable = true;
      uninstallUnmanaged = true;
      update = {
        onActivation = false;
        auto = {
          enable = true;
          onCalendar = "daily";
        };
      };
      restartOnFailure = {
        enable = true;
        restartDelay = "60s";
        exponentialBackoff = {
          enable = true;
          steps = 10;
          maxDelay = "1h";
        };
      };
      overrides.global = {
        Context = {
          devices = [ "dri" ];
          filesystems = [
            "xdg-config/gtk-3.0:ro"
            "xdg-config/gtk-4.0:ro"
            "xdg-config/fontconfig:ro"
            "/run/current-system/sw/share/fonts:ro"
          ];
        };
      };
      remotes = lib.mkDefault [
        {
          name = "flathub";
          location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
        }
        {
          name = "xiaoxioe-flatpak";
          location = "file:///home/${config.my.user.name}/CloudStorage/gdrive-union-decrypted/custom-flatpaks/repo";
          args = "--no-gpg-verify";
        }
      ];
    };

    systemd.services.flatpak-managed-install = {
      restartIfChanged = false;
      reloadIfChanged = false;
      stopIfChanged = false;
      wantedBy = lib.mkForce [ ];
    };

    environment.systemPackages = [ syncFlatpakRepoScript ];
  };
}
