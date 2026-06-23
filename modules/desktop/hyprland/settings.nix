{ ... }:
{
  # Configure Hyprland general settings
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    configType = "hyprlang";

    settings = {
      source = [ "~/.config/hypr/dms/colors.conf" ];

      # Monitors
      monitor = [
        ",preferred,auto,auto"
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
          natural_scroll = false;
          # tap-to-click = true;
        };
        sensitivity = 0;
      };

      # General aesthetics (curated dark mode theme)
      general = {
        gaps_in = 4;
        gaps_out = 8;
        border_size = 2;
        layout = "dwindle";
        resize_on_border = true;
      };

      # Decoration (Rounding, Blur, Shadow)
      decoration = {
        rounding = 12;
        rounding_power = 2;
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
        enabled = true;
        bezier = [
          # "wind, 0.05, 0.9, 0.1, 1.05"
          # "winIn, 0.1, 1.1, 0.1, 1.1"
          # "winOut, 0.3, -0.3, 0, 1"
          # "liner, 1, 1, 1, 1"
          "easeOutQuint, 0.23, 1, 0.32, 1"
          "easeInOutCubic, 0.65, 0.05, 0.36, 1"
          "linear, 0, 0, 1, 1"
          "almostLinear, 0.5, 0.5, 0.75, 1"
          "quick, 0.15, 0, 0.1, 1"
        ];
        animation = [
          # "windows, 1, 6, wind, slide"
          # "windowsIn, 1, 6, winIn, slide"
          # "windowsOut, 1, 5, winOut, slide"
          # "windowsMove, 1, 5, wind, slide"
          # "border, 1, 1, liner"
          # "fade, 1, 10, default"
          # "workspaces, 1, 5, wind, slidefade 20%"
          "global,        1,     10,    default"
          "border,        1,     5.39,  easeOutQuint"
          "windows,       1,     4.79,  easeOutQuint"
          "windowsIn,     1,     4.1,   easeOutQuint, popin 87%"
          "windowsOut,    1,     1.49,  linear,       popin 87%"
          "fadeIn,        1,     1.73,  almostLinear"
          "fadeOut,       1,     1.46,  almostLinear"
          "fade,          1,     3.03,  quick"
          "layers,        1,     3.81,  easeOutQuint"
          "layersIn,      1,     4,     easeOutQuint, fade"
          "layersOut,     1,     1.5,   linear,       fade"
          "fadeLayersIn,  1,     1.79,  almostLinear"
          "fadeLayersOut, 1,     1.39,  almostLinear"
          "workspaces,    1,     1.94,  almostLinear, fade"
          "workspacesIn,  1,     1.21,  almostLinear, fade"
          "workspacesOut, 1,     1.94,  almostLinear, fade"
          "zoomFactor,    1,     7,     quick"
        ];
      };

      # Layout settings
      dwindle = {
        preserve_split = true;
      };

      gesture = [
        "3, horizontal, workspace"
      ];

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
