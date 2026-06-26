{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.terminal.tmux";
  description = "Tmux configuration";

  hmConfig = hmOpts: {
    programs.tmux = {
      enable = true;
      shortcut = "a";
      baseIndex = 1;
      mouse = true;
      escapeTime = 0;
      terminal = "screen-256color";
      newSession = false;
      extraConfig = ''
        bind | split-window -h
        bind - split-window -v
        unbind '"'
        unbind %
        bind r source-file ~/.config/tmux/tmux.conf \; display "Tmux Reloaded!"
      '';
      plugins = with pkgs.tmuxPlugins; [
        sensible
        catppuccin
        {
          plugin = resurrect;
          extraConfig = ''
            set -g @resurrect-strategy-vim 'session'
            set -g @resurrect-strategy-nvim 'session'
            set -g @resurrect-capture-pane-contents 'on'
          '';
        }
        {
          plugin = continuum;
          extraConfig = ''
            set -g @continuum-restore 'on'
            set -g @continuum-boot 'on'
          '';
        }
      ];
    };
  };
}
