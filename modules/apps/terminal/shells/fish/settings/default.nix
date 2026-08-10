{
  pkgs,
  lib,
  config,
  osConfig,
  flakePath,
  selfLib,
  ...
}:
{
  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      # Override plugin 'done' agar selalu mengirim notifikasi walau terminal sedang fokus
      function __done_is_process_window_focused
          return 1
      end

      set -g fish_greeting
      fish_add_path $HOME/.local/bin
      set -p fish_function_path $HOME/.config/fish/functions/custom
      ${lib.optionalString (osConfig.sops.secrets ? "ninerouter-key") ''
        if test -r ${osConfig.sops.secrets."ninerouter-key".path}
            set -lx NINEROUTER_KEY (cat ${osConfig.sops.secrets."ninerouter-key".path})
        end
      ''}
      ${lib.optionalString (osConfig.sops.secrets ? "cloudflare-token") ''
        if test -r ${osConfig.sops.secrets."cloudflare-token".path}
            set -gx CLOUDFLARE_TOKEN (cat ${osConfig.sops.secrets."cloudflare-token".path})
        end
      ''}

        # GPG SSH Agent Integration
        set -gx SSH_AUTH_SOCK "$XDG_RUNTIME_DIR/gnupg/S.gpg-agent.ssh"

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
      {
        name = "done";
        inherit (done) src;
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

      # --- NIXOS REBUILD & MAINTENANCE ---
      rebuild = "sudo nixos-rebuild switch --flake . --print-build-logs --show-trace";
      cln = "nh clean all --keep 3 --ask --optimise";
      nfu = "nix flake update";
      osbuild = "nh os switch --no-nom --show-trace --diff auto --ask -L";
      ostest = "nh os test --no-nom --show-trace --diff auto --ask -L";
      osboot = "nh os boot --no-nom --show-trace --diff auto --ask -L";
    };
  };

  xdg.configFile = selfLib.mkHmSymlinks config {
    "fish/history_blacklist" =
      "${flakePath}/modules/apps/terminal/shells/fish/settings/dotfiles/history_blacklist";
  };
}
