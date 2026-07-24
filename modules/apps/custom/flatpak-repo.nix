{
  pkgs,
  inputs,
  selfLib,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  custom = inputs.custompkgs.packages.${system};
  priv = inputs.custompkgs-priv.packages.${system};
in
selfLib.mkModule {
  name = "apps.custom.flatpak-repo";
  description = "Private Flatpak applications and repository sync service";

  flatpakCfg = {
    "com.portswigger.BurpSuitePro" = {
      enable = true;
      origin = "xiaoxioe-flatpak";
      binName = "burpsuitepro";
      nativePkgs = priv.burpsuitepro;
    };
    "io.github.xiaoyouchr.GhostDownloader" = {
      enable = true;
      origin = "xiaoxioe-flatpak";
      binName = "ghost-downloader";
      nativePkgs = custom.ghost-downloader-3;
    };
  };

  hmConfig = hmOpts: {
    systemd.user.services.sync-flatpak-repo = {
      Unit = {
        Description = "Update private Flatpaks from Google Drive mount";
        X-SwitchMethod = "keep-old";
        After = [
          "network-online.target"
          "rclone-mount.service"
        ];
        Wants = [
          "network-online.target"
          "rclone-mount.service"
        ];
      };

      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.writeShellScript "sync-flatpak-repo" ''
          set -eu
          REPO_PATH="$HOME/CloudStorage/union-raid1-decrypted/custom-flatpaks/repo"

          echo "Waiting for Google Drive FUSE mount and repository directory..."
          mounted=false
          for i in {1..120}; do
            if [ -d "$REPO_PATH" ]; then
              mounted=true
              break
            fi
            sleep 5
          done

          if [ "$mounted" = false ]; then
            echo "ERROR: Google Drive mount or repository directory is not available. Skipping Flatpak update."
            exit 0
          fi

          echo "Repository directory found. Running Flatpak update..."
          ${pkgs.flatpak}/bin/flatpak update --user -y io.github.xiaoyouchr.GhostDownloader com.portswigger.BurpSuitePro
        ''}";
      };
    };

    systemd.user.timers.sync-flatpak-repo = {
      Unit = {
        Description = "Timer for updating private Flatpaks from Google Drive mount";
      };
      Timer = {
        OnStartupSec = "4m";
        RandomizedDelaySec = "30s";
        Persistent = false;
      };
      Install = {
        WantedBy = [ "timers.target" ];
      };
    };
  };
}
