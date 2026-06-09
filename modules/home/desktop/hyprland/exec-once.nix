{ config, lib, ... }:
let
  cfg = config.my.user.desktop.hyprland;
in
{
  config = lib.mkIf cfg.enable {
    wayland.windowManager.hyprland.settings.exec-once = [
      "dbus-update-activation-environment --all --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
      "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"

      "wl-paste --type text --watch cliphist store"
      "wl-paste --type image --watch cliphist store"

      "uwsm app -- caelestia shell"
    ];
  };
}
