_: {
  programs.niri.settings = {
    # Layer Rules (from config.kdl & dms/wpblur.kdl)
    layer-rules = [
      {
        matches = [ { namespace = "^quickshell$"; } ];
        place-within-backdrop = true;
      }
      {
        matches = [ { namespace = "dms:blurwallpaper"; } ];
        place-within-backdrop = true;
      }
    ];

    # Window Rules (Merged from config.kdl, dms/layout.kdl, dms/windowrules.kdl)
    window-rules = [
      # Global DMS Window Rule (from dms/layout.kdl)
      {
        matches = [ { } ];
        geometry-corner-radius = {
          top-left = 12.0;
          top-right = 12.0;
          bottom-right = 12.0;
          bottom-left = 12.0;
        };
        clip-to-geometry = true;
        tiled-state = true;
        draw-border-with-background = false;
      }

      # Fullscreen / Open Maximized Rules (from dms/windowrules.kdl)
      {
        matches = [ { app-id = "^(firefox|org\\.mozilla\\.firefox)$"; } ];
        open-maximized = true;
      }
      {
        matches = [
          { app-id = "^(thunderbird|org\\.mozilla\\.thunderbird)$"; }
          { app-id = "^eu\\.betterbird\\.Betterbird$"; }
        ];
        open-maximized = true;
      }
      {
        matches = [ { app-id = "^(codium|com\\.vscodium\\.codium)$"; } ];
        open-maximized = true;
      }
      {
        matches = [ { app-id = "^org\\.kde\\.dolphin$"; } ];
        open-maximized = true;
      }
      {
        matches = [
          { app-id = "^kitty$"; }
          { app-id = "^Alacritty$"; }
          { app-id = "^foot$"; }
        ];
        open-maximized = true;
      }
      {
        matches = [
          { app-id = "^app\\.zen_browser\\.zen\\.zen-beta$"; }
          { app-id = "zen"; }
        ];
        open-maximized = true;
      }
      {
        matches = [
          { app-id = "^gnome-control-center$"; }
          { app-id = "^pavucontrol$"; }
          { app-id = "^nm-connection-editor$"; }
        ];
        default-column-width = {
          proportion = 0.5;
        };
        open-floating = false;
      }
      {
        matches = [
          { app-id = "^org\\.gnome\\.Calculator$"; }
          { app-id = "^gnome-calculator$"; }
          { app-id = "^galculator$"; }
          { app-id = "^xdg-desktop-portal$"; }
        ];
        open-floating = true;
      }
      {
        matches = [
          {
            app-id = "^steam$";
            title = "^notificationtoasts_\\d+_desktop$";
          }
        ];
        default-floating-position = {
          x = 10;
          y = 10;
          relative-to = "bottom-right";
        };
        open-focused = false;
      }
      {
        matches = [
          { app-id = "zen"; }
          { app-id = "kitty"; }
        ];
        draw-border-with-background = false;
      }
      {
        matches = [
          {
            app-id = "firefox$";
            title = "^Picture-in-Picture$";
          }
          { app-id = "zoom"; }
        ];
        open-floating = true;
      }
      {
        matches = [
          { app-id = "org.quickshell$"; }
          { app-id = "com.danklinux.dms$"; }
        ];
        open-floating = true;
      }
    ];
  };
}
