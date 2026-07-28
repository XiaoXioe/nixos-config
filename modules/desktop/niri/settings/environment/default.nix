{ pkgs, ... }:
{
  programs.niri.package = pkgs.niri;

  programs.niri.settings = {
    # Input Configuration (from config.kdl)
    input = {
      keyboard = {
        xkb = {
          layout = "";
          model = "";
          rules = "";
          variant = "";
        };
        repeat-delay = 300;
        repeat-rate = 35;
        track-layout = "global";
      };
      touchpad = {
        tap = true;
        natural-scroll = true;
      };
    };

    # System & Notification
    config-notification = {
      disable-failed = true;
    };

    gestures = {
      hot-corners = {
        enable = false;
      };
    };

    overview = {
      workspace-shadow = {
        enable = false;
      };
    };

    # Environment Variables
    environment = {
      XDG_CURRENT_DESKTOP = "niri";
      QT_QPA_PLATFORM = "wayland;xcb";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
      QT_QPA_PLATFORMTHEME = "gtk3";
      QT_QPA_PLATFORMTHEME_QT6 = "gtk3";
      TERMINAL = "kitty";
    };

    # Autostart Processes
    spawn-at-startup = [
      {
        command = [
          "dms"
          "run"
        ];
      }
      {
        command = [
          "killall"
          "ibus-daemon"
        ];
      }
    ];

    hotkey-overlay = {
      skip-at-startup = true;
    };

    prefer-no-csd = true;
    screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";

    debug = {
      honor-xdg-activation-with-invalid-serial = true;
    };
  };
}
