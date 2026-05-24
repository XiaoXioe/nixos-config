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

    # Disk
    auto-mount = selfLib.enabled;

    # Sistem settings
    fonts = selfLib.enabled;
    locale = selfLib.enabled;
    graphics = selfLib.enabled;
    bootloader = selfLib.enabled;
    environment = selfLib.enabled;
    nix-settings = selfLib.enabled;
    optimizations = selfLib.enabled;

    # Impermanence — bind-mount file & direktori penting ke /persist
    preservation = selfLib.enabled;

    # Security and Pentesting
    gnupg = selfLib.enabled;
    secrets = selfLib.enabled;
    keyring = selfLib.enabled;
    security = selfLib.enabled;
    networking = selfLib.enabled;
    compatibility = selfLib.enabled;
    packages-security = selfLib.enabled;
    security-wrappers = selfLib.enabled;
    security-tools-system = selfLib.enabled;

    # Virtualization & AI
    llama = selfLib.enabled;
    ollama = selfLib.enabled;
    nullclaw = selfLib.disabled;
    waydroid = selfLib.enabled;
    open-webui = selfLib.disabled;
    packages-vm = selfLib.enabled;
    packages-ai = selfLib.enabled;
    virtualization = {
      enable = true;
      mt5.enable = false;
    };

    # Desktop settings
    niri = selfLib.enabled;
    kde = {
      enable = true;
      unstable = false;
    };
    gnome = selfLib.disabled;
    greeter = selfLib.enabled;
    hyprland = selfLib.enabled;

    # Spesialisasi
    gt610 = selfLib.disabled;
    daily = selfLib.disabled;
    kernel = selfLib.disabled;
    retro-gaming = selfLib.disabled;

    # Custom shell
    rebuild-wrapper = selfLib.enabled;
    compsize-wrapper = selfLib.enabled;
    show-zombie-parents = selfLib.enabled;
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
