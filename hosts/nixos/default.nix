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
    # --- System Identity ---
    hostname = hostName;

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
      optimizations.enable = true;
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
      core.enable = true;
      openssh.enable = true;
      tmpfiles.enable = true;
      networking = {
        dns.enable = true;
        vpn.enable = true;
      };
      scheduling = {
        ananicy.enable = true;
        snapper.enable = true;
        gamemode.enable = false;
        ssd-monitor.enable = true;
      };
      boot-speedup.enable = true;
    };

    apps = {
      browsers.firefox.enable = true;
    };

    ai = {
      llama.enable = true;
      ollama.enable = true;
      open-webui.enable = true;
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

    specialization = {
      daily.enable = false;
      retro-gaming.enable = false;
    };
  };

  system.stateVersion = "25.11";
}
