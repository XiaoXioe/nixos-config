{
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.terminal.emulators.kitty";
  description = "Kitty terminal configuration with Catppuccin Mocha theme and Zellij keybindings";

  hmConfig = {
    programs.kitty = {
      enable = true;
      font = {
        name = "monospace";
        size = 10;
      };
      settings = {
        # General UI & Window
        enable_audio_bell = false;
        scrollback_lines = 10000;
        window_padding_width = 4;
        enabled_layouts = "splits,stack,fat,tall,grid";

        # Auto Copy Selected Text to Clipboard
        copy_on_select = "clipboard";
        strip_trailing_spaces = "smart";

        # Tab Bar Styling (Slanted Powerline & Centered)
        tab_bar_edge = "top";
        tab_bar_align = "center";
        tab_bar_style = "powerline";
        tab_powerline_style = "slanted";
        tab_title_template = " {title} ";
        active_tab_font_style = "bold";
        inactive_tab_font_style = "normal";

        # Catppuccin Mocha Color Palette
        background = "#1e1e2e";
        foreground = "#cdd6f4";
        selection_background = "#f5e0dc";
        selection_foreground = "#1e1e2e";
        url_color = "#f5e0dc";
        cursor = "#f5e0dc";
        cursor_text_color = "#1e1e2e";

        # Tab Bar Colors
        active_tab_background = "#89b4fa";
        active_tab_foreground = "#1e1e2e";
        inactive_tab_background = "#181825";
        inactive_tab_foreground = "#cdd6f4";
        tab_bar_background = "#11111b";

        # Split Borders
        active_border_color = "#89b4fa";
        inactive_border_color = "#45475a";
        bell_border_color = "#f38ba8";

        # 16 Terminal Colors
        color0 = "#45475a";
        color1 = "#f38ba8";
        color2 = "#a6e3a1";
        color3 = "#f9e2af";
        color4 = "#89b4fa";
        color5 = "#f5c2e7";
        color6 = "#94e2d5";
        color7 = "#bac2de";
        color8 = "#585b70";
        color9 = "#f38ba8";
        color10 = "#a6e3a1";
        color11 = "#f9e2af";
        color12 = "#89b4fa";
        color13 = "#f5c2e7";
        color14 = "#94e2d5";
        color15 = "#a6adc8";
      };

      keybindings = {
        # Tab Management (Zellij keybinds)
        "ctrl+n" = "new_tab_with_cwd";
        "ctrl+t" = "new_tab_with_cwd";
        "alt+t" = "new_tab_with_cwd";
        "ctrl+w" = "close_tab";
        "ctrl+pagedown" = "next_tab";
        "ctrl+pageup" = "previous_tab";
        "ctrl+shift+pagedown" = "move_tab_forward";
        "ctrl+shift+pageup" = "move_tab_backward";

        # Pane / Split Management (Zellij keybinds)
        "alt+d" = "launch --location=hsplit --cwd=current";
        "alt+r" = "launch --location=vsplit --cwd=current";
        "alt+w" = "close_window";

        # Pane Navigation (Zellij keybinds)
        "alt+left" = "neighboring_window left";
        "alt+right" = "neighboring_window right";
        "alt+up" = "neighboring_window up";
        "alt+down" = "neighboring_window down";
        "alt+h" = "neighboring_window left";
        "alt+l" = "neighboring_window right";
        "alt+k" = "neighboring_window up";
        "alt+j" = "neighboring_window down";

        # Fullscreen / Zoom Pane (Zellij keybinds)
        "alt+z" = "toggle_layout stack";
        "alt+f" = "toggle_layout stack";
      };
    };
  };
}
