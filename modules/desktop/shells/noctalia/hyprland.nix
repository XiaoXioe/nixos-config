{ osConfig, lib, ... }:
let
  d = osConfig.my.desktop;
  isEnabled =
    (d ? hyprland && d.hyprland ? noctalia && d.hyprland.noctalia.enable)
    || (d ? shells && d.shells ? noctalia && d.shells.noctalia.enable);
in
{
  wayland.windowManager.hyprland.settings = lib.mkIf isEnabled {
    # Startup
    "exec-once" = [
      (if osConfig.programs.hyprland.withUWSM then "uwsm app -- noctalia" else "noctalia")
    ];

    # Blur rules for Noctalia surfaces
    layerrule = [
      "blur on, match:namespace noctalia:.*"
      "ignore_alpha 0.7, match:namespace noctalia:.*"
      "blur on, match:namespace notifications"
      "ignore_alpha 0.69, match:namespace notifications"
      "blur on, match:namespace launcher"
      "ignore_alpha 0.5, match:namespace launcher"
      "blur on, match:namespace session"
    ];

    # Noctalia IPC keybinds
    bind = [
      "SUPER, Space, exec, noctalia msg panel-toggle launcher"
      "SUPER, Period, exec, noctalia msg panel-toggle launcher /emo"
      "SUPER, X, exec, noctalia msg panel-toggle control-center"
      "SUPER, N, exec, noctalia msg panel-toggle control-center"
      "SUPER, A, exec, noctalia msg panel-toggle control-center notifications"
      "SUPER, V, exec, noctalia msg panel-toggle clipboard"
      "CTRL SUPER, T, exec, noctalia msg panel-toggle wallpaper"
      "SUPER SHIFT, W, exec, noctalia msg panel-toggle wallpaper"
      "SUPER, Z, exec, noctalia msg settings-toggle"
      "SUPER, I, exec, noctalia msg settings-toggle"
      "SUPER, Tab, exec, noctalia msg window-switcher"
      "SUPER, L, exec, noctalia msg session lock"
      "SUPER ALT, C, exec, noctalia msg panel-toggle session"
      "SUPER SHIFT, S, exec, noctalia msg screenshot-region"
      ", Print, exec, noctalia msg screenshot-region"
      "CTRL, Print, exec, noctalia msg screenshot-fullscreen"
      "SUPER, Print, exec, noctalia msg screenshot-fullscreen"
    ];

    # Volume, brightness, media (repeat-enabled, work when locked)
    bindel = [
      ", XF86AudioRaiseVolume, exec, noctalia msg volume-up 3"
      ", XF86AudioLowerVolume, exec, noctalia msg volume-down 3"
      ", XF86MonBrightnessUp, exec, noctalia msg brightness-up"
      ", XF86MonBrightnessDown, exec, noctalia msg brightness-down"
    ];

    bindl = [
      ", XF86AudioMute, exec, noctalia msg volume-mute"
      ", XF86AudioMicMute, exec, noctalia msg mic-mute"
      ", XF86AudioPlay, exec, noctalia msg media toggle"
      ", XF86AudioNext, exec, noctalia msg media next"
      ", XF86AudioPrev, exec, noctalia msg media previous"
    ];
  };
}
