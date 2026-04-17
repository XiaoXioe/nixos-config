{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.system.hyprland;
in
{
  options.my.system.hyprland = {
    enable = selfLib.mkBoolOpt false "Hyprland Wayland compositor";
  };

  config = lib.mkIf cfg.enable {
    # Aktifkan Hyprland di level sistem (sudah include XDG portal wayland)
    programs.hyprland = {
      enable = true;
      withUWSM = true; # Universal Wayland Session Manager (lebih stabil)
      xwayland.enable = true; # kalau kamu masih pakai aplikasi X11
    };

    # Package pendukung level sistem
    environment.systemPackages = with pkgs; [
      hyprpicker # Color picker untuk Hyprland
      hyprshot # Screenshot tool
      wl-clipboard # Clipboard Wayland
      brightnessctl # Kontrol brightness
      playerctl # MPRIS media player control (dipakai Caelestia)
    ];
  };
}
