{
  config,
  lib,
  pkgs,
  selfLib,
  fullName,
  ...
}:

let
  cfg = config.my.user.git;
in
{
  options.my.user.git = {
    enable = selfLib.mkBoolOpt false "user git configuration";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      diff-so-fancy # git diff with colors
      git-crypt # git files encryption
      hub # github command-line client
      tig # diff and commit view
    ];

    programs.gh = {
      enable = true;
      package = pkgs.gh;
      settings = {
        git_protocol = "ssh";
        prompt = "enabled";
        editor = "sublime -w";
      };
    };

    programs.git = {
      enable = true;
      package = pkgs.git;

      settings = {
        user = {
          name = fullName;
          email = "169626976+XiaoXioe@users.noreply.github.com";
        };

        safe = {
          directory = [
            "${config.home.homeDirectory}/nixos-config"
            "${config.home.homeDirectory}/nix-custompkgs-priv"
          ];
        };

        # Mengatur default branch selalu ke 'main' (bukan 'master')
        init = {
          defaultBranch = "main";
        };

        # Otomatis set upstream saat push branch baru
        push = {
          autoSetupRemote = true;
        };

        # Menggunakan rebase saat pull untuk menghindari merge commit yang berantakan
        pull = {
          rebase = true;
        };
      };
    };
  };
}
