# Host-level NixOS configuration for KleinMoretti.
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

    # ── Core ──────────────────────────────────────────────────────
    core = {
      packages.enable = true;
      fonts.enable = true;
      locale.enable = true;
      graphics.enable = true;
      bootloader.enable = true;
      environment.enable = true;
      nix-settings.enable = true;
      optimizations.enable = true;
      pipewireEffects = {
        enable = true;
        preset = "perfect-eq"; # or "autogain"
      };
    };

    # ── Hardware ──────────────────────────────────────────────────
    hardware = {
      auto-mount.enable = true;
      preservation.enable = true; # Ephemeral root — bind-mount critical files to /persist
    };

    # ── Security ──────────────────────────────────────────────────
    security = {
      gnupg.enable = true;
      secrets.enable = true;
      keyring.enable = true;
      hardening.enable = true;
      networking.enable = true;
      compatibility.enable = true;
      packages.enable = true;
      wrappers.enable = true;
      tools.enable = true;
    };

    # ── AI ────────────────────────────────────────────────────────
    ai = {
      llama.enable = true;
      ollama.enable = true;
      open-webui.enable = false;
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

    # ── Desktop ───────────────────────────────────────────────────
    desktop = {
      niri.enable = true;
      kde = {
        enable = true;
        unstable = false;
      };
      gnome.enable = false;
      greeter.enable = true;
      hyprland.enable = true;
    };

    # ── Specialisations ───────────────────────────────────────────
    specialisation = {
      daily.enable = false;
      retro-gaming.enable = false;
    };
  };

  my.custompkgs = {
    # Custom shell wrappers
    rebuild-wrapper.enable = true;
    compsize-wrapper.enable = true;
    git-commits.enable = true;
    show-zombie-parents.enable = true;
    cek-cache.enable = true;
    dl-lagu.enable = true;
    ollama-to-llama.enable = true;
  };

  my.system.services = {
    openssh.enable = true;
    ananicy.enable = true;
    dnscrypt.enable = true;
    vpn-auto.enable = true;

    ssd-tbw.enable = true;
    snapper.enable = true;
    gamemode.enable = false;
    tmpfiles.enable = true;
    nm-speedup.enable = false;
    system-service.enable = true;
  };

  system.stateVersion = "25.11";
}
