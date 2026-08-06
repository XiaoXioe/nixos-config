{ pkgs, osConfig, ... }:
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
        numlock = true;
        repeat-delay = 250;
        repeat-rate = 50;
        track-layout = "global";
      };
      mouse = {
        accel-speed = 0.4;
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
    };

    # Autostart Processes
    spawn-at-startup = [
      {
        command = [
          "dbus-update-activation-environment"
          "--systemd"
          "WAYLAND_DISPLAY"
          "DISPLAY"
          "XDG_CURRENT_DESKTOP"
        ];
      }
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
      {
        command = [
          osConfig.my.defaultTerminal
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
