{
  lib,
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.terminal.emulators.foot";
  description = "Foot terminal configuration";

  hmConfig = hmOpts: {
    programs.foot = {
      enable = true;
      settings = {
        main = {
          term = "xterm-256color";
          font = "FiraCode Nerd Font:size=8:style=Retina";
          dpi-aware = "yes";
          pad = "6x6";
          selection-target = "both";
        };
        scrollback = {
          lines = 10000;
          multiplier = 3;
          indicator-position = "relative";
          indicator-format = "line";
        };
        url = {
          launch = "${pkgs.xdg-utils}/bin/xdg-open \${url}";
          label-letters = "sadfjklewcmpgh";
          osc8-underline = "url-mode";
        };
        cursor = {
          style = "beam";
          beam-thickness = 2;
        };
        bell = {
          command-focused = "yes";
          notify = "yes";
          urgent = "yes";
        };
        desktop-notifications = {
          command = "${pkgs.libnotify}/bin/notify-send -a \${app-id} -i \${app-id} \${title} \${body}";
        };

        mouse = {
          hide-when-typing = "yes";
        };
        tweak = {
          font-monospace-warn = "no";
          sixel = "yes";
        };
        colors-dark = {
          alpha = 0.95;
          background = "1e1e2e";
          foreground = "cdd6f4";
          regular0 = "45475a";
          regular1 = "f38ba8";
          regular2 = "a6e3a1";
          regular3 = "f9e2af";
          regular4 = "89b4fa";
          regular5 = "f5c2e7";
          regular6 = "94e2d5";
          regular7 = "bac2de";
          bright0 = "585b70";
          bright1 = "f38ba8";
          bright2 = "a6e3a1";
          bright3 = "f9e2af";
          bright4 = "89b4fa";
          bright5 = "f5c2e7";
          bright6 = "94e2d5";
          bright7 = "a6adc8";
        };
      };
    };
  };
}
