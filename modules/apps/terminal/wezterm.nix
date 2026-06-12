{
  config,
  lib,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.terminal.wezterm";
  description = "Wezterm configuration";

  hmConfig = {
    programs.wezterm = {
      enable = true;
      extraConfig = ''
          local wezterm = require 'wezterm'
          local config = wezterm.config_builder()
          config.color_scheme = 'Catppuccin Mocha'
          config.font = wezterm.font('Adwaita Mono')
          config.font_size = 13.0
          config.window_decorations = "NONE"
          config.window_background_opacity = 0.95
          config.use_fancy_tab_bar = false
          config.tab_bar_at_bottom = true
          config.hide_tab_bar_if_only_one_tab = true
          config.front_end = "OpenGL"
          config.audible_bell = "Disabled"
          config.keys = {
            { key = 't', mods = 'CTRL', action = wezterm.action.SpawnTab 'CurrentPaneDomain' },
            { key = 'w', mods = 'CTRL', action = wezterm.action.CloseCurrentTab { confirm = false } },
          }
          return config
      '';
    };
  };
}
