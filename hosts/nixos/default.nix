# Host-level NixOS configuration for KleinMoretti.
# Refactored to Unified Nested Architecture.
{
  userName,
  hostName,
  fullName,
  flakePath,
  allUsers,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
  ];

  my = {
    # --- User Management ---
    users = allUsers;

    user = {
      name = userName;
      fullName = fullName;
      flakePath = flakePath;
    };

    # --- Refactored Nested Modules ---
    core = {
      nix.enable = true;
    };

    apps = {
      browsers.firefox.enable = true;
    };

    # --- Legacy System Modules (to be refactored) ---
    system = {
      hostname = hostName;

      ai = {
        llama.enable = true;
        ollama.enable = true;
        open-webui.enable = true;
      };

      core = {
        pipewire = {
          enable = true;
          pipewireEffects = {
            perfectEq.enable = true;
            autogain.enable = true;
          };
        };
        fonts.enable = true;
        locale.enable = true;
        packages.enable = true;
        graphics.enable = true;
        bootloader.enable = true;
        environment.enable = true;
        # nix-settings is now handled by my.core.nix
        nix-settings.enable = false;
        optimizations.enable = true;
      };

      desktop = {
        kde.enable = true;
        niri.enable = true;
        steam.enable = true;
        gnome.enable = false;
        greeter.enable = true;
      };

      hardware = {
        auto-mount.enable = true;
        preservation.enable = true;
      };

      security = {
        gnupg.enable = true;
        compat.enable = true;
        pentest.enable = true;
        secrets.enable = true;
        keyring.enable = true;
        packages.enable = true;
        wrappers.enable = true;
        hardening.enable = true;
        networking.enable = true;
      };

      services = {
        base.enable = true;
        openssh.enable = true;
        ananicy.enable = true;
        snapper.enable = true;
        bootSpeedup.enable = true;
        tmpfiles.enable = true;
        dnscrypt.enable = true;
        vpn-auto.enable = true;
        gamemode.enable = false;
        ssd-monitor.enable = true;
      };

      virtualisation = {
        waydroid.enable = true;
        packages.enable = true;
        docker = {
          enable = true;
          autoUpdate = true;
          mt5.enable = false;
          "9router".enable = true;
        };
      };
    };
  };

  system.stateVersion = "25.11";
}
