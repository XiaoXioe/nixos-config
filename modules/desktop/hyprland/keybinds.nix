{
  osConfig,
  ...
}:
let
  isNoctalia =
    (osConfig.my.desktop.hyprland ? noctalia && osConfig.my.desktop.hyprland.noctalia.enable)
    || (osConfig.my.desktop.shells ? noctalia && osConfig.my.desktop.shells.noctalia.enable);
in
{
  # Configure Hyprland keybindings - aligned with Niri's hotkeys
  wayland.windowManager.hyprland.settings = {
    "$mod" = "SUPER";

    bind = [
      # Applications
      "$mod, T, exec, $TERMINAL"
      "$mod, B, exec, $BROWSER"
      "$mod, Q, killactive,"
      "$mod SHIFT, E, exit,"
      "$mod SHIFT, T, togglefloating,"
      "$mod, F, fullscreen, 0"
    ]
    ++ (
      if isNoctalia then
        [
          # Noctalia v5 IPC Binds
          "$mod, Space, exec, noctalia msg panel-toggle launcher"
          "$mod, Period, exec, noctalia msg panel-toggle launcher /emo"
          "$mod, X, exec, noctalia msg panel-toggle control-center"
          "$mod, N, exec, noctalia msg panel-toggle control-center"
          "$mod, A, exec, noctalia msg panel-toggle control-center notifications"
          "$mod, V, exec, noctalia msg panel-toggle clipboard"
          "CTRL SUPER, T, exec, noctalia msg panel-toggle wallpaper"
          "$mod SHIFT, W, exec, noctalia msg panel-toggle wallpaper"
          "$mod, Z, exec, noctalia msg settings-toggle"
          "$mod, I, exec, noctalia msg settings-toggle"
          "$mod, Tab, exec, noctalia msg window-switcher"
          "$mod, L, exec, noctalia msg session lock"
          "$mod ALT, C, exec, noctalia msg panel-toggle session"

          # Screenshots & Shared Wayland Tools
          "$mod SHIFT, S, exec, noctalia msg screenshot-region"
          ", Print, exec, noctalia msg screenshot-region"
          "CTRL, Print, exec, noctalia msg screenshot-fullscreen"
          "$mod, Print, exec, noctalia msg screenshot-fullscreen"
          "CTRL SHIFT, S, exec, wayland-scan-ocr"
          "CTRL SHIFT, Q, exec, wayland-scan-qr"
          "$mod SHIFT, A, exec, wayland-scan-annotate"
        ]
      else
        [
          # Default Wayland screenshot & tool binds
          "$mod SHIFT, S, exec, grim -g \"$(slurp)\" - | wl-copy"
          ", Print, exec, grim - | wl-copy"
          "CTRL, Print, exec, grim - | wl-copy"
          "CTRL SHIFT, S, exec, wayland-scan-ocr"
          "CTRL SHIFT, Q, exec, wayland-scan-qr"
          "$mod SHIFT, A, exec, wayland-scan-annotate"
        ]
    )
    ++ [
      # Window Focus Movement
      "$mod, left, movefocus, l"
      "$mod, right, movefocus, r"
      "$mod, up, movefocus, u"
      "$mod, down, movefocus, d"

      # Move Windows / Swap position
      "$mod SHIFT, left, swapwindow, l"
      "$mod SHIFT, right, swapwindow, r"
      "$mod SHIFT, up, swapwindow, u"
      "$mod SHIFT, down, swapwindow, d"

      # Workspace Switching
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

      # Move Active Window to Workspace
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

      # Relative Workspace Navigation
      "$mod, U, workspace, r+1"
      "$mod, I, workspace, r-1"
      "$mod SHIFT, U, movetoworkspace, r+1"
      "$mod SHIFT, I, movetoworkspace, r-1"

      # Scratchpad/Special Workspace
      "$mod, S, togglespecialworkspace, magic"
      "$mod CTRL, S, movetoworkspace, special:magic"

      # Scroll through existing workspaces with mainMod + scroll
      "$mod, mouse_down, workspace, e+1"
      "$mod, mouse_up, workspace, e-1"
    ];

    # Media, Brightness and Audio keys (work when locked and repeat)
    bindel =
      if isNoctalia then
        [
          ", XF86AudioRaiseVolume, exec, noctalia msg volume-up 3"
          ", XF86AudioLowerVolume, exec, noctalia msg volume-down 3"
          ", XF86MonBrightnessUp, exec, noctalia msg brightness-up"
          ", XF86MonBrightnessDown, exec, noctalia msg brightness-down"
        ]
      else
        [
          ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%+"
          ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-"
          ", XF86MonBrightnessUp, exec, brightnessctl set 5%+"
          ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
        ];

    bindl =
      if isNoctalia then
        [
          ", XF86AudioMute, exec, noctalia msg volume-mute"
          ", XF86AudioMicMute, exec, noctalia msg mic-mute"
          ", XF86AudioPlay, exec, noctalia msg media toggle"
          ", XF86AudioNext, exec, noctalia msg media next"
          ", XF86AudioPrev, exec, noctalia msg media previous"
        ]
      else
        [
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
