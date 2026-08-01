{
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.terminal.emulators.alacritty";
  description = "Alacritty GPU-accelerated terminal configuration";

  hmConfig = hmOpts: {
    programs.alacritty = {
      enable = true;
      settings = {
        env = {
          TERM = "xterm-256color";
        };

        window = {
          opacity = 0.95;
          padding = {
            x = 4;
            y = 4;
          };
          decorations = "None";
        };

        font = {
          normal = {
            family = "FiraCode Nerd Font";
            style = "Retina";
          };
          bold = {
            family = "DejaVu Sans Mono";
            style = "Bold";
          };
          size = 10;
        };

        colors = {
          primary = {
            background = "#1e1e2e";
            foreground = "#cdd6f4";
          };
          cursor = {
            text = "#1e1e2e";
            cursor = "#f5e0dc";
          };
          normal = {
            black = "#45475a";
            red = "#f38ba8";
            green = "#a6e3a1";
            yellow = "#f9e2af";
            blue = "#89b4fa";
            magenta = "#f5c2e7";
            cyan = "#94e2d5";
            white = "#bac2de";
          };
          bright = {
            black = "#585b70";
            red = "#f38ba8";
            green = "#a6e3a1";
            yellow = "#f9e2af";
            blue = "#89b4fa";
            magenta = "#f5c2e7";
            cyan = "#a6adc8";
          };
        };
      };
    };
  };
}
