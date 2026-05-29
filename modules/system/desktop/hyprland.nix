{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.my.system.hyprland;
in
{
  options.my.system.hyprland = {
    enable = lib.mkEnableOption "Hyprland Wayland compositor";
  };

  config = lib.mkIf cfg.enable {
    # Enable Hyprland at the system level (includes XDG Wayland portal)
    programs.hyprland = {
      enable = true;
      withUWSM = true; # Universal Wayland Session Manager (lebih stabil)
      xwayland.enable = true; # kalau kamu masih pakai aplikasi X11
    };

    # Package pendukung level sistem
    environment.systemPackages = with pkgs; [
      hyprpicker # Color picker for Hyprland
      hyprshot # Screenshot tool
      wl-clipboard # Clipboard Wayland
      brightnessctl # Kontrol brightness
      playerctl # MPRIS media player control (dipakai Caelestia)
    ];
  };
}
