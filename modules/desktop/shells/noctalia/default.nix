{
  selfLib,
  lib,
  pkgs,
  flakePath,
  ...
}:

selfLib.mkModule {
  name = "desktop.shells.noctalia";
  description = "Noctalia v5 native Wayland desktop shell";

  preservation = {
    userDirectories = [
      ".cache/noctalia"
      ".local/share/noctalia"
      ".local/state/noctalia"
    ];
  };

  nixosConfig = {
    # System-level dependencies for Noctalia
    environment.systemPackages = with pkgs; [
      satty
      brightnessctl
      playerctl
      hyprpicker
      libqalculate
      power-profiles-daemon
      upower
      wl-clipboard
      cliphist
    ];

    services.upower.enable = true;
    services.power-profiles-daemon.enable = lib.mkDefault true;
  };

  hmConfig =
    { config, ... }:
    {
      imports = [
        ./niri.nix
        ./hyprland.nix
      ];

      home.packages = [
        (selfLib.fetchCachePinned "noctalia")
      ];

      home.file.".local/state/noctalia/settings.toml".source =
        config.lib.file.mkOutOfStoreSymlink "${flakePath}/modules/desktop/shells/noctalia/settings.toml";
    };
}
