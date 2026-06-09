{ config, pkgs, lib, ... }:
let
  cfg = config.my.user.desktop.hyprland;
in
{
  options.my.user.desktop.hyprland = {
    enable = lib.mkEnableOption "Hyprland Wayland compositor";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      awww
      grimblast
      hyprpicker
      grim
      slurp
      wl-clip-persist
      cliphist
      wf-recorder
      glib
      wayland
      tesseract
      # dari system module
      hyprshot
      brightnessctl
      playerctl
    ];

    systemd.user.targets.hyprland-session.Unit.Wants = [
      "xdg-desktop-autostart.target"
    ];

    wayland.windowManager.hyprland = {
      enable = true;
      # package & portal diinstall langsung oleh HM
      # package = null;   <-- dihapus, biar pakai default
      # portalPackage = null; <-- dihapus, biar pakai default

      xwayland.enable = true;

      systemd = {
        enable = true;
        variables = [ "--all" ];
      };
    };
  };
}
