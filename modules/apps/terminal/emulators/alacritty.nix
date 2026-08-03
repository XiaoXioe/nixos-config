{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.terminal.emulators.alacritty";
  description = "Alacritty GPU-accelerated terminal configuration";

  hmConfig = hmOpts: {
    home.packages = [ pkgs.libnotify ];

    programs.alacritty = {
      enable = true;
      settings = {
        env = {
          TERM = "xterm-256color";
        };

        bell = {
          duration = 300;
          command = {
            program = "${pkgs.bash}/bin/bash";
            args = [
              "-c"
              ''
                export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/1000/bus"
                win_title=$(${pkgs.niri}/bin/niri msg --json windows 2>/dev/null | ${pkgs.jq}/bin/jq -r '.[] | select(.app_id | test("Alacritty"; "i")) | .title' | ${pkgs.coreutils}/bin/head -n 1)
                app_header="''${win_title:-"Alacritty Terminal"}"
                ${pkgs.libnotify}/bin/notify-send -i terminal -a "$app_header" "🔔 Terminal Bell" "Proses / Agent pada '$app_header' telah memicu sinyal selesai!"
              ''
            ];
          };
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
