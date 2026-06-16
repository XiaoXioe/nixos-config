{
  pkgs,
  config,
  flakePath,
  ...
}:
{
  # --- FZF: Fuzzy Finder ---
  programs = {
    fzf = {
      enable = true;
      enableFishIntegration = true;
      colors = {
        "bg+" = "#3b4252";
        "fg+" = "#e5e9f0";
        "hl+" = "#81a1c1";
        "pointer" = "#b48ead";
        "marker" = "#a3be8c";
      };
      defaultOptions = [
        "--preview 'echo {}'"
        "--preview-window down:3:wrap"
      ];
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    zoxide = {
      enable = true;
      enableFishIntegration = true;
    };

    eza = {
      enable = true;
      enableFishIntegration = true;
      icons = "auto";
      git = true;
    };

    fish = {
      enable = true;
      interactiveShellInit = ''
        set -g fish_greeting
        set -g fish_history_filter '^[ ]'
        set -p fish_function_path $HOME/.config/fish/functions/custom
        if test -r /run/secrets/ninerouter-key
            set -lx NINEROUTER_KEY (cat /run/secrets/ninerouter-key)
        end
        if test -r /run/secrets/cloudflare-token
            set -gx CLOUDFLARE_TOKEN (cat /run/secrets/cloudflare-token)
        end

        set -g fish_color_command cdd6f4
        set -g fish_color_param 89b4fa
        set -g fish_color_quote f9e2af
        set -g fish_color_error f38ba8
        set -g fish_color_escape f5c2e7
        set -g fish_color_operator 94e2d5
      '';

      plugins = with pkgs.fishPlugins; [
        {
          name = "async-prompt";
          src = async-prompt;
        }
        {
          name = "autopair";
          src = autopair;
        }
      ];

      shellAbbrs = {
        gl = "gallery-dl";
        aria = "aria2c -x16 -s16 -c '' -o ''";
      };
    };
  };

  xdg.configFile."fish/functions/custom".source =
    config.lib.file.mkOutOfStoreSymlink "${flakePath}/dotfiles/fish/functions";
}
