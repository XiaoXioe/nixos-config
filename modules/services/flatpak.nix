{
  lib,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "services.flatpak";

  nixosConfig = {
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
      ];
    };

    systemd.timers.flatpak-managed-install-timer.timerConfig.RandomizedDelaySec = "15min";
  };
}
