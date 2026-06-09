{ config, lib, ... }:
let
  cfg = config.my.user.desktop.hyprland;
in
{
  config = lib.mkIf cfg.enable {
    wayland.windowManager.hyprland.settings = {
      binds = {
        scroll_event_delay = 100;
        movefocus_cycles_fullscreen = true;
      };

      bind = [
        # show keybinds list
        "$mod, F1, exec, show-keybinds"

        # keybindings
        "$mod, Return, exec, wezterm"
        "$mod, B, exec, firefox"

        "$mod, Q, killactive,"
        "$mod, F, fullscreen, 0"
        "$mod SHIFT, F, fullscreen, 1"

        "$mod, Space, exec, caelestia shell drawers toggle launcher"
        "$mod, d, exec, caelestia shell drawers toggle session"

        "$mod x, Escape, exec, power-menu"
        "$mod, P, exec, power-profile-menu"
        "$mod, T, exec, toggle-oppacity"
        "$mod, E, exec, nemo"
        "$mod, C ,exec, hyprpicker -a"
        "$mod, W,exec, wallpaper-picker"

        "$mod, XF86Display, exec, toggle-display"

        # screenshot
        "$mod S, exec, screenshot --copy"
        "$mod, Print, exec, screenshot --save"
        "$mod SHIFT, Print, exec, screenshot --swappy"

        # OCR
        "$mod CTRL, O, exec, ocr"

        # switch focus
        "$mod, left,  movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up,    movefocus, u"
        "$mod, down,  movefocus, d"

        "$mod, left,  alterzorder, top"
        "$mod, right, alterzorder, top"
        "$mod, up,    alterzorder, top"
        "$mod, down,  alterzorder, top"

        "CTRL ALT, up, exec, hyprctl dispatch focuswindow floating"
        "CTRL ALT, down, exec, hyprctl dispatch focuswindow tiled"

        # switch workspace
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"
        "$mod, 0, workspace, 10"

        # same as above, but switch to the workspace
        "$mod SHIFT, 1, movetoworkspacesilent, 1" # movetoworkspacesilent
        "$mod SHIFT, 2, movetoworkspacesilent, 2"
        "$mod SHIFT, 3, movetoworkspacesilent, 3"
        "$mod SHIFT, 4, movetoworkspacesilent, 4"
        "$mod SHIFT, 5, movetoworkspacesilent, 5"
        "$mod SHIFT, 6, movetoworkspacesilent, 6"
        "$mod SHIFT, 7, movetoworkspacesilent, 7"
        "$mod SHIFT, 8, movetoworkspacesilent, 8"
        "$mod SHIFT, 9, movetoworkspacesilent, 9"
        "$mod SHIFT, 0, movetoworkspacesilent, 10"
        "$mod CTRL, c, movetoworkspace, empty"

        # window control
        "$mod SHIFT, left, movewindow, l"
        "$mod SHIFT, right, movewindow, r"
        "$mod SHIFT, up, movewindow, u"
        "$mod SHIFT, down, movewindow, d"

        "$mod CTRL, left, resizeactive, -80 0"
        "$mod CTRL, right, resizeactive, 80 0"
        "$mod CTRL, up, resizeactive, 0 -80"
        "$mod CTRL, down, resizeactive, 0 80"

        "$mod ALT, left, moveactive,  -80 0"
        "$mod ALT, right, moveactive, 80 0"
        "$mod ALT, up, moveactive, 0 -80"
        "$mod ALT, down, moveactive, 0 80"

        # media and volume controls
        ", XF86AudioPlay,exec, playerctl play-pause"
        ", XF86AudioNext,exec, playerctl next"
        ", XF86AudioPrev,exec, playerctl previous"
        ", XF86AudioStop,exec, playerctl stop"

        "$mod, mouse_down, workspace, e-1"
        "$mod, mouse_up, workspace, e+1"

      ];

      # mouse binding
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      bindl = [
        ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"

        ", XF86MonBrightnessUp, caelestia:brightnessUp"
        ", XF86MonBrightnessDown, caelestia:brightnessDown"
      ];

    };
  };
}
