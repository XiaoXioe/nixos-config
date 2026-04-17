{
  selfLib,
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

  # --- MODULAR USERS (SISTEM) ---
  my.users = allUsers;

  my.user = {
    name = userName;
    fullName = fullName;
    flakePath = flakePath;
  };

  # --- MODULAR SYSTEM (GLOBAL) ---
  my.system = {
    hostname = hostName;
    packages = selfLib.enabled;

    # Sistem settings
    fonts = selfLib.enabled;
    locale = selfLib.enabled;
    graphics = selfLib.enabled;
    bootloader = selfLib.enabled;
    environment = selfLib.enabled;
    nix-settings = selfLib.enabled;
    optimizations = selfLib.enabled;

    # Security and Pentesting
    gnupg = selfLib.enabled;
    secrets = selfLib.enabled;
    security = selfLib.enabled;
    networking = selfLib.enabled;
    compatibility = selfLib.enabled;
    packages-security = selfLib.enabled;
    security-wrappers = selfLib.enabled;
    security-tools-system = selfLib.enabled;

    # Virtualization & AI
    ollama = selfLib.enabled;
    nullclaw = selfLib.enabled;
    waydroid = selfLib.enabled;
    open-webui = selfLib.disabled;
    ghidra-mcp = selfLib.disabled;
    packages-vm = selfLib.enabled;
    packages-ai = selfLib.enabled;
    virtualization = selfLib.enabled;

    # Desktop settings
    niri = selfLib.enabled;
    kde = selfLib.disabled;
    gnome = selfLib.disabled;
    greeter = selfLib.enabled;
    hyprland = selfLib.enabled;

    # Spesialisasi
    daily = selfLib.disabled;
    kernel = selfLib.disabled;
    retro-gaming = selfLib.disabled;

    # Custom shell
    rebuild-wrapper = selfLib.enabled;
    compsize-wrapper = selfLib.enabled;
    show-zombie-parents = selfLib.enabled;

    # Disk configuration
    auto-mount = selfLib.enabled;
    rollback = {
      device = "/dev/disk/by-uuid/9617790f-27d0-460e-8f00-fa94f1d0e68d";
    };
    impermanence = {
      enable = false;
    };
  };

  my.services = {
    psd = selfLib.disabled;
    openssh = selfLib.enabled;
    ananicy = selfLib.enabled;
    dnscrypt = selfLib.enabled;
    vpn-auto = selfLib.enabled;
    btrfs-config = selfLib.disabled;

    ssd-tbw = selfLib.enabled;
    snapper = selfLib.enabled;
    gamemode = selfLib.disabled;
    tmpfiles = selfLib.enabled;
    teldrive = selfLib.disabled;
    nm-speedup = selfLib.enabled;
    system-service = selfLib.enabled;
  };

  # Mematikan pembuatan dokumentasi sistem untuk mempercepat rebuild
  documentation = {
    enable = false;
    man.enable = false;
    info.enable = false;
    doc.enable = false;
    nixos.enable = false;
  };

  system.stateVersion = "25.11";
}
