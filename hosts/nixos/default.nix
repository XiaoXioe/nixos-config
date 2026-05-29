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
    packages.enable = true;

    # Disk
    auto-mount.enable = true;

    # Core
    fonts.enable = true;
    locale.enable = true;
    graphics.enable = true;
    bootloader.enable = true;
    environment.enable = true;
    nix-settings.enable = true;
    optimizations.enable = true;

    # Ephemeral root — bind-mount critical files to /persist
    preservation.enable = true;

    # Security
    gnupg.enable = true;
    secrets.enable = true;
    keyring.enable = true;
    security.enable = true;
    networking.enable = true;
    compatibility.enable = true;
    packages-security.enable = true;
    security-wrappers.enable = true;
    security-tools-system.enable = true;

    # Virtualization & AI
    llama.enable = true;
    ollama.enable = true;
    nullclaw.enable = false;
    waydroid.enable = true;
    open-webui.enable = false;
    packages-vm.enable = true;
    packages-ai.enable = true;
    virtualization = {
      enable = true;
      mt5.enable = false;
    };

    # Desktop
    niri.enable = true;
    kde = {
      enable = true;
      unstable = false;
    };
    gnome.enable = false;
    greeter.enable = true;
    hyprland.enable = true;

    # Specializations
    gt610.enable = false;
    daily.enable = false;
    kernel.enable = false;
    retro-gaming.enable = false;

    # Custom shell wrappers
    rebuild-wrapper.enable = true;
    compsize-wrapper.enable = true;
    show-zombie-parents.enable = true;
  };

  my.services = {
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
