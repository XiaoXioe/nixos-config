{ ... }:
{
  # Configure Hyprland general settings
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    configType = "hyprlang";

    settings = {
      # Monitors
      monitor = [
        ",preferred,auto,1"
      ];

      # Exec once (startup scripts/apps)
      "exec-once" = [
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "caelestia shell -d"
      ];

      # Input configuration
      input = {
        kb_layout = "us";
        follow_mouse = 1;
        touchpad = {
          natural_scroll = true;
          tap-to-click = true;
        };
        sensitivity = 0;
      };

      # General aesthetics (curated dark mode theme)
      general = {
        gaps_in = 4;
        gaps_out = 8;
        border_size = 2;
        "col.active_border" = "rgba(cba6f7ff) rgba(89b4faff) 45deg"; # Mauve to Blue gradient
        "col.inactive_border" = "rgba(313244ff)"; # Crust/Base color
        layout = "dwindle";
        resize_on_border = true;
      };

      # Decoration (Rounding, Blur, Shadow)
      decoration = {
        rounding = 12;
        active_opacity = 0.95;
        inactive_opacity = 0.90;

        blur = {
          enabled = true;
          size = 6;
          passes = 3;
          new_optimizations = true;
          ignore_opacity = true;
        };

        shadow = {
          enabled = true;
          range = 15;
          render_power = 3;
          color = "rgba(11111b66)";
        };
      };

      # Animations (Smooth, fluid modern animations)
      animations = {
        enable = true;
        bezier = [
          "wind, 0.05, 0.9, 0.1, 1.05"
          "winIn, 0.1, 1.1, 0.1, 1.1"
          "winOut, 0.3, -0.3, 0, 1"
          "liner, 1, 1, 1, 1"
        ];
        animation = [
          "windows, 1, 6, wind, slide"
          "windowsIn, 1, 6, winIn, slide"
          "windowsOut, 1, 5, winOut, slide"
          "windowsMove, 1, 5, wind, slide"
          "border, 1, 1, liner"
          "fade, 1, 10, default"
          "workspaces, 1, 5, wind, slidefade 20%"
        ];
      };

      # Layout settings
      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      gestures = {
        workspace_swipe = true;
        workspace_swipe_fingers = 3;
      };

      misc = {
        force_default_wallpaper = 0;
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        mouse_move_enables_dpms = true;
        key_press_enables_dpms = true;
      };
    };
  };
}
