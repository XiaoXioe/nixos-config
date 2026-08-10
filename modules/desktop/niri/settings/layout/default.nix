_: {
  programs.niri.settings = {
    # Cursor Settings (from dms/cursor.kdl)
    cursor = {
      theme = "Vimix-white-cursors";
      size = 24;
    };

    # Layout Settings (merged from config.kdl, dms/layout.kdl, dms/colors.kdl)
    layout = {
      gaps = 6;
      background-color = "transparent";
      center-focused-column = "never";

      preset-column-widths = [
        { proportion = 0.33333; }
        { proportion = 0.5; }
        { proportion = 0.66667; }
      ];
      default-column-width = {
        proportion = 0.5;
      };

      border = {
        enable = false;
        width = 2;
        active = {
          color = "#8ccff1";
        };
        inactive = {
          color = "#8a9297";
        };
        urgent = {
          color = "#ffb4ab";
        };
      };

      focus-ring = {
        enable = true;
        width = 2;
        active = {
          color = "#8ccff1";
        };
        inactive = {
          color = "#8a9297";
        };
        urgent = {
          color = "#ffb4ab";
        };
      };

      shadow = {
        enable = true;
        softness = 30;
        spread = 5;
        offset = {
          x = 0;
          y = 5;
        };
        color = "#00000070";
        draw-behind-window = false;
      };

      tab-indicator = {
        gap = 4.0;
        width = 2.0;
        length = {
          total-proportion = 0.5;
        };
        position = "left";
        gaps-between-tabs = 0.0;
        corner-radius = 0.0;
        active = {
          color = "#8ccff1";
        };
        inactive = {
          color = "#8a9297";
        };
        urgent = {
          color = "#ffb4ab";
        };
      };

      insert-hint = {
        display = {
          color = "#8ccff180";
        };
      };

      struts = { };
    };
  };
}
