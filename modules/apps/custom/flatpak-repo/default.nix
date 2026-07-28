{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:

let
  syncFlatpakRepoScript = pkgs.writeShellScriptBin "sync-flatpak-repo" ''
    set -euo pipefail

    REPO_DIR="$HOME/CloudStorage/gdrive-union-decrypted/custom-flatpaks/repo"
    REMOTE_NAME="xiaoxioe-flatpak"
    RCLONE_MOUNT_POINT="$HOME/CloudStorage/gdrive-union-decrypted"
    RC_URL="http://127.0.0.1:5572"

    echo "==> [sync-flatpak-repo] Checking rclone FUSE mount..."
    if ! ${pkgs.util-linux}/bin/mountpoint -q "$RCLONE_MOUNT_POINT"; then
      echo "ERROR: Rclone FUSE mount is not active at $RCLONE_MOUNT_POINT"
      exit 1
    fi

    echo "==> [sync-flatpak-repo] Refreshing Rclone VFS cache via RC API..."
    if ${pkgs.curl}/bin/curl -s -f -X POST "$RC_URL/vfs/refresh?recursive=true&dir=custom-flatpaks" > /dev/null 2>&1; then
      echo "==> [sync-flatpak-repo] VFS cache refreshed successfully."
    else
      echo "WARNING: Rclone RC endpoint unreachable at $RC_URL/vfs/refresh. Proceeding with filesystem check..."
    fi

    echo "==> [sync-flatpak-repo] Verifying repository path..."
    if [ ! -d "$REPO_DIR" ]; then
      echo "ERROR: Custom Flatpak repository directory not found at $REPO_DIR"
      exit 1
    fi

    echo "==> [sync-flatpak-repo] Aligning Flatpak remote URL..."
    ${pkgs.flatpak}/bin/flatpak remote-modify --system --url="file://$REPO_DIR" "$REMOTE_NAME" || true
    ${pkgs.flatpak}/bin/flatpak remote-modify --user --url="file://$REPO_DIR" "$REMOTE_NAME" || true

    echo "==> [sync-flatpak-repo] Triggering non-interactive Flatpak update..."
    ${pkgs.flatpak}/bin/flatpak update --system -y || true
    ${pkgs.flatpak}/bin/flatpak update --user -y || true

    echo "==> [sync-flatpak-repo] Sync completed successfully."
  '';
in
selfLib.mkModule {
  name = "apps.custom.flatpak-repo";
  description = "Flatpak service configuration, private applications, and repository sync service";

  nixosConfig = {
    my.services.system.tmpfiles.nocowDirectories = [ "/mnt/data_btrfs/flatpak-userdata" ];

    systemd.tmpfiles.rules = [
      "d /mnt/data_btrfs/flatpak-userdata 0755 ${config.my.user.name} users - -"
      "d /mnt/data_btrfs/flatpak-local 0755 ${config.my.user.name} users - -"
      "d /mnt/data_btrfs/containers 0755 ${config.my.user.name} users - -"
      "d /home/${config.my.user.name}/CloudStorage 0755 ${config.my.user.name} users - -"
      "d /home/${config.my.user.name}/.var 0755 ${config.my.user.name} users - -"
      "d /home/${config.my.user.name}/.local 0755 ${config.my.user.name} users - -"
      "d /home/${config.my.user.name}/.local/share 0755 ${config.my.user.name} users - -"
      "L+ /home/${config.my.user.name}/.var/app - - - - /mnt/data_btrfs/flatpak-userdata"
      "L+ /home/${config.my.user.name}/.local/share/flatpak - - - - /mnt/data_btrfs/flatpak-local"
      "L+ /home/${config.my.user.name}/.local/share/containers - - - - /mnt/data_btrfs/containers"
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
      # wantedBy = lib.mkForce [ ];
    };

    environment.systemPackages = [ syncFlatpakRepoScript ];
  };

  flatpakCfg = {
    "com.portswigger.BurpSuitePro" = {
      enable = false;
      origin = "xiaoxioe-flatpak";
      binName = "burpsuitepro";
    };
    "io.github.xiaoyouchr.GhostDownloader" = {
      enable = false;
      origin = "xiaoxioe-flatpak";
      binName = "ghost-downloader";
    };
  };

  hmConfig = hmOpts: {
    home.packages = [ syncFlatpakRepoScript ];
  };
}
