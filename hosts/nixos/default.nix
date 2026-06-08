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

    # ── Core overrides ────────────────────────────────────────────
    core = {
      pipewireEffects = {
        enable = true;
        preset = "perfect-eq"; # or "autogain"
      };
    };

    # ── Security overrides ─────────────────────────────────────────
    security = {
      networking.enable = true;
      pentest.enable = true;
    };

    # ── AI ─────────────────────────────────────────────────────────
    ai = {
      llama.enable = true;
      ollama.enable = true;
      open-webui.enable = false;
    };

    # ── Virtualisation ────────────────────────────────────────────
    virtualisation = {
      waydroid.enable = true;
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
      hyprland.enable = true;
      steam.enable = true;
    };

    # ── Specialisations ───────────────────────────────────────────
    specialisation = {
      daily.enable = false;
      retro-gaming.enable = false;
    };
  };

  my.custompkgs = {
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
    ssd-monitor.enable = true;
    snapper.enable = true;
    gamemode.enable = false;
    nm-speedup.enable = false;
  };

  system.stateVersion = "25.11";
}
