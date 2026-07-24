{
  lib,
  config,
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
  description = "Flatpak service configuration, private applications, and repository sync service";

  nixosConfig = {
    my.services.system.tmpfiles.nocowDirectories = [ "/mnt/data_btrfs/flatpak-userdata" ];

    systemd.tmpfiles.rules = [
      "d /mnt/data_btrfs/flatpak-userdata 0755 ${config.my.user.name} users - -"
      "d /mnt/data_btrfs/flatpak-local 0755 ${config.my.user.name} users - -"
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
          location = "file:///home/${config.my.user.name}/CloudStorage/union-raid1-decrypted/custom-flatpaks/repo";
          args = "--no-gpg-verify";
        }
      ];
    };

    systemd.services.flatpak-managed-install = {
      restartIfChanged = false;
      stopIfChanged = false;
      wantedBy = lib.mkForce [ ];
    };

    systemd.timers.flatpak-managed-install-timer.timerConfig.RandomizedDelaySec = "15min";
  };

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
    home.activation.setupFlatpakSymlinks = hmOpts.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # Pastikan direktori penampung di home ada
      ${pkgs.coreutils}/bin/mkdir -p "$HOME/.var"
      ${pkgs.coreutils}/bin/mkdir -p "$HOME/.local/share"

      # Buat symlink langsung (ln -sfn) dari home ke target host
      # Hapus folder target asli jika ada untuk mencegah nested symlink
      if [ -d "$HOME/.var/app" ] && [ ! -L "$HOME/.var/app" ]; then
        ${pkgs.coreutils}/bin/rm -rf "$HOME/.var/app"
      fi
      if [ -d "$HOME/.local/share/flatpak" ] && [ ! -L "$HOME/.local/share/flatpak" ]; then
        ${pkgs.coreutils}/bin/rm -rf "$HOME/.local/share/flatpak"
      fi
      if [ -d "$HOME/.local/share/containers" ] && [ ! -L "$HOME/.local/share/containers" ]; then
        ${pkgs.coreutils}/bin/rm -rf "$HOME/.local/share/containers"
      fi

      ${pkgs.coreutils}/bin/ln -sfn /mnt/data_btrfs/flatpak-userdata "$HOME/.var/app"
      ${pkgs.coreutils}/bin/ln -sfn /mnt/data_btrfs/flatpak-local "$HOME/.local/share/flatpak"
      ${pkgs.coreutils}/bin/ln -sfn /mnt/data_btrfs/containers "$HOME/.local/share/containers"
    '';

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
