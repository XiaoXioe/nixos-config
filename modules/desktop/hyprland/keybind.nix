{ ... }:
{
  # Configure Hyprland keybindings - aligned with Niri's hotkeys
  wayland.windowManager.hyprland.settings = {
    "$mod" = "SUPER";

    bind = [
      # Applications
      "$mod, T, exec, wezterm"
      "$mod, B, exec, firefox"
      "$mod, Q, killactive,"
      "$mod SHIFT, E, exit,"
      "$mod SHIFT, T, togglefloating,"
      "$mod, F, fullscreen, 0"

      # Caelestia Shell IPC Drawer Toggles (Aligned with spotlight/dashboard/utilities in DMS)
      "$mod, Space, exec, caelestia shell drawers toggle launcher"
      "$mod, D, exec, caelestia shell drawers toggle dashboard"
      "$mod ALT, U, exec, caelestia shell drawers toggle utilities"

      # Window Focus Movement (Niri: Arrow Keys)
      "$mod, left, movefocus, l"
      "$mod, right, movefocus, r"
      "$mod, up, movefocus, u"
      "$mod, down, movefocus, d"

      # Move Windows / Swap position (Niri: Shift + Arrow Keys)
      "$mod SHIFT, left, swapwindow, l"
      "$mod SHIFT, right, swapwindow, r"
      "$mod SHIFT, up, swapwindow, u"
      "$mod SHIFT, down, swapwindow, d"

      # Workspace Switching (Niri: Mod + 1..9)
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

      # Move Active Window to Workspace (Niri: Mod + Shift + 1..9)
      "$mod SHIFT, 1, movetoworkspace, 1"
      "$mod SHIFT, 2, movetoworkspace, 2"
      "$mod SHIFT, 3, movetoworkspace, 3"
      "$mod SHIFT, 4, movetoworkspace, 4"
      "$mod SHIFT, 5, movetoworkspace, 5"
      "$mod SHIFT, 6, movetoworkspace, 6"
      "$mod SHIFT, 7, movetoworkspace, 7"
      "$mod SHIFT, 8, movetoworkspace, 8"
      "$mod SHIFT, 9, movetoworkspace, 9"
      "$mod SHIFT, 0, movetoworkspace, 10"

      # Relative Workspace Navigation (Niri: Mod + U/I and Mod + Shift + U/I)
      "$mod, U, workspace, r+1"
      "$mod, I, workspace, r-1"
      "$mod SHIFT, U, movetoworkspace, r+1"
      "$mod SHIFT, I, movetoworkspace, r-1"

      # Scratchpad/Minimize-like behavior
      "$mod, S, togglespecialworkspace, magic"
      "$mod CTRL, S, movetoworkspace, special:magic"

      # Screenshots
      "$mod SHIFT, S, exec, grim -g \"$(slurp)\" - | wl-copy"
      "CTRL, Print, exec, grim - | wl-copy"

      # Scroll through existing workspaces with mainMod + scroll
      "$mod, mouse_down, workspace, e+1"
      "$mod, mouse_up, workspace, e-1"
    ];

    # Media, Brightness and Audio keys (work when locked and repeat)
    bindel = [
      ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%+"
      ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-"
      ", XF86MonBrightnessUp, exec, brightnessctl set 5%+"
      ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
    ];

    bindl = [
      ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
      ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
      ", XF86AudioPlay, exec, playerctl play-pause"
      ", XF86AudioNext, exec, playerctl next"
      ", XF86AudioPrev, exec, playerctl previous"
    ];

    # Move/resize windows with mod + LMB/RMB and dragging
    bindm = [
      "$mod, mouse:272, movewindow"
      "$mod, mouse:273, resizewindow"
    ];
  };
}
