{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.user.apps.terminal.wezterm;
in
{
  options.my.user.apps.terminal.wezterm = {
    enable = lib.mkEnableOption "Wezterm configuration";
  };

  config = lib.mkIf cfg.enable {
    programs.wezterm = {
      enable = true;

      extraConfig = ''
          local wezterm = require 'wezterm'
          local config = wezterm.config_builder()

          -- Tema Warna
          -- Tersedia varian: 'Catppuccin Mocha' (gelap), 'Catppuccin Macchiato', 'Catppuccin Frappe', 'Catppuccin Latte' (terang)
          config.color_scheme = 'Catppuccin Mocha'

          -- Pengaturan Font
          -- Pastikan font Adwaita Mono sudah ada di environment NixOS kamu
          config.font = wezterm.font('Adwaita Mono')
          config.font_size = 13.0

          -- Estetika & Window Management (Cocok untuk ekosistem Wayland/Niri)
          -- Menghilangkan "title bar" bawaan jendela agar terlihat rata dan bersih
          config.window_decorations = "NONE"

          -- Memberikan efek transparan tipis agar menyatu dengan background desktop
          config.window_background_opacity = 0.95

          -- Pengaturan Tab
          config.use_fancy_tab_bar = false           -- Menggunakan tab bar bergaya retro/minimalis
          config.tab_bar_at_bottom = true            -- Memindahkan tab ke bawah layar
          config.hide_tab_bar_if_only_one_tab = true -- Menyembunyikan tab jika hanya ada 1 jendela aktif

          -- Tweaks Performa
          -- Memastikan rendering menggunakan OpenGL yang terbukti sangat stabil untuk Intel HD Graphics
          config.front_end = "OpenGL"

          -- Mematikan bell suara yang seringkali mengganggu
          config.audible_bell = "Disabled"

          -- ==========================================
        -- Custom Keybindings
        -- ==========================================
        config.keys = {
          -- Membuka tab baru dengan Ctrl+T
          {
            key = 't',
            mods = 'CTRL',
            action = wezterm.action.SpawnTab 'CurrentPaneDomain'
          },

          -- Menutup tab saat ini dengan Ctrl+W (tanpa dialog konfirmasi)
          {
            key = 'w',
            mods = 'CTRL',
            action = wezterm.action.CloseCurrentTab { confirm = false }
          },
        }

          return config
      '';
    };
  };
}
