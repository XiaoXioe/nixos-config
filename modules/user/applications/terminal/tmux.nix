{
  config,
  lib,
  pkgs,
  selfLib,
  ...
}:

let
  cfg = config.my.user.tmux;
in
{
  options.my.user.tmux = {
    enable = selfLib.mkBoolOpt false "Tmux configuration";
  };

  config = lib.mkIf cfg.enable {
    programs.tmux = {
      enable = true;

      # Mengubah prefix bawaan dari Ctrl+b menjadi Ctrl+a (lebih mudah dijangkau)
      shortcut = "a";

      # Memulai penomoran window dan pane dari 1, bukan 0
      baseIndex = 1;

      # Mengaktifkan dukungan mouse untuk scrolling, klik pane, dan resize
      mouse = true;

      # Menghilangkan jeda saat menekan tombol ESC
      escapeTime = 0;

      # Memastikan warna terminal dirender dengan benar
      terminal = "screen-256color";

      # Otomatis membuat sesi baru jika tidak ada sesi yang menempel (attach)
      newSession = false;

      # Memasukkan konfigurasi kustom ala tmux.conf
      extraConfig = ''
        # Mempermudah split pane menggunakan | (vertikal) dan - (horizontal)
        bind | split-window -h
        bind - split-window -v
        unbind '"'
        unbind %

        # Navigasi antar pane menggunakan tombol ala Vim (h, j, k, l)
        bind h select-pane -L
        bind j select-pane -D
        bind k select-pane -U
        bind l select-pane -R

        # Memuat ulang konfigurasi tmux dengan cepat menggunakan Prefix + r
        bind r source-file ~/.config/tmux/tmux.conf \; display "Tmux Reloaded!"
      '';

      # Rekomendasi Plugin
      plugins = with pkgs.tmuxPlugins; [
        sensible # Sekumpulan opsi default yang sangat berguna
        catppuccin # Tema yang modern dan estetik

        {
          plugin = resurrect; # Menyimpan sesi tmux agar tidak hilang saat PC restart
          extraConfig = ''
            set -g @resurrect-strategy-vim 'session'
            set -g @resurrect-strategy-nvim 'session'
            set -g @resurrect-capture-pane-contents 'on'
          '';
        }
        {
          plugin = continuum; # Menyimpan sesi secara otomatis setiap 15 menit
          extraConfig = ''
            set -g @continuum-restore 'on'
            set -g @continuum-boot 'on'
          '';
        }
      ];
    };
  };
}
