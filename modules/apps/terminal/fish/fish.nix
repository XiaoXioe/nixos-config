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

        # --- SYSTEMD & JOURNALCTL ---
        sc = "sudo systemctl";
        scu = "systemctl --user";
        scstart = "sudo systemctl start";
        scstop = "sudo systemctl stop";
        screstart = "sudo systemctl restart";
        scstatus = "systemctl status";
        scfailed = "systemctl --failed";

        jc = "journalctl -xe";
        jcf = "journalctl -f";
        jcu = "journalctl --user -xe";
        jceu = "sudo journalctl -xeu";

        # --- GIT ---
        gcp = "git add . && git commit -m 'update' && git push";

        # --- NIXOS REBUILD & MAINTENANCE ---
        rebuild = "sudo nixos-rebuild switch --flake --print-build-logs --show-trace";
        cln = "nh clean all --keep 3 --ask --optimise";
        nfu = "nix flake update";
        osbuild = "nh os switch --no-nom --show-trace --diff auto --ask -L";
        ostest = "nh os test --no-nom --show-trace --diff auto --ask -L";
        osboot = "nh os boot --no-nom --show-trace --diff auto --ask -L";
      };
    };
  };

  xdg.configFile."fish/functions/custom".source =
    config.lib.file.mkOutOfStoreSymlink "${flakePath}/dotfiles/fish/functions";

  xdg.configFile."fish/history_blacklist".source =
    config.lib.file.mkOutOfStoreSymlink "${flakePath}/dotfiles/fish/history_blacklist";
}
