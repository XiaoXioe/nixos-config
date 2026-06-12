# Host-level NixOS configuration for KleinMoretti.
# Only host-specific overrides; defaults are set in modules.
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

  # --- User Management ---
  my.users = allUsers;

  my.user = {
    name = userName;
    fullName = fullName;
    flakePath = flakePath;
  };

  # --- System Modules ---
  my.system = {
    hostname = hostName;

    # ── AI ─────────────────────────────────────────────────────────
    ai = {
      llama.enable = true;
      ollama.enable = true;
      open-webui.enable = true;
    };

    # ── Core overrides ────────────────────────────────────────────
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
      nix-settings.enable = true;
      optimizations.enable = true;
    };

    # ── Desktop ───────────────────────────────────────────────────
    desktop = {
      kde.enable = true;
      niri.enable = true;
      steam.enable = true;
      gnome.enable = false;
      greeter.enable = true;
    };

    # ── Hardware ───────────────────────────────────────────────────
    hardware = {
      auto-mount.enable = true;
      preservation.enable = true;
    };

    # ── Security overrides ─────────────────────────────────────────
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

    # ── Specialisations ───────────────────────────────────────────
    specialisation = {
      daily.enable = false;
      retro-gaming.enable = false;
    };

    # ── Virtualisation ────────────────────────────────────────────
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

  # --- Scripts (managed via userFeatures / home-manager) ---
  # Script toggles are in lib/users.nix > userFeatures.scripts

  my.system.services = {
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

  system.stateVersion = "25.11";
}
