{
  lib,
  selfLib,
  config,
  pkgs,
  ...
}:

selfLib.mkModule {
  name = "services.flatpak";

  nixosConfig = {
    my.services.tmpfiles.nocowDirectories = [ "/mnt/data_btrfs/flatpak-userdata" ];

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
  };
}
