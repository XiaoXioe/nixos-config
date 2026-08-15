{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.dev.vcs.git";
  description = "User git configuration";

  nixosConfig = {
    sops.secrets =
      lib.genAttrs
        [
          "github-user-1"
          "github-access-token-1"
          "github-user-2"
          "github-access-token-2"
          "github-user-3"
          "github-access-token-3"
        ]
        (_: {
          sopsFile = ./secrets.yaml;
          owner = config.my.user.name;
          mode = "0400";
        });

    sops.templates."gh_hosts.yml" = {
      path = "/home/${config.my.user.name}/.config/gh/hosts.yml";
      owner = config.my.user.name;
      mode = "0600";
      content = ''
        github.com:
            user: ${config.sops.placeholder."github-user-1"}
            users:
                ${config.sops.placeholder."github-user-1"}:
                    oauth_token: ${config.sops.placeholder."github-access-token-1"}
                    git_protocol: ssh
                ${config.sops.placeholder."github-user-2"}:
                    oauth_token: ${config.sops.placeholder."github-access-token-2"}
                    git_protocol: ssh
                ${config.sops.placeholder."github-user-3"}:
                    oauth_token: ${config.sops.placeholder."github-access-token-3"}
                    git_protocol: ssh
            oauth_token: ${config.sops.placeholder."github-access-token-1"}
            git_protocol: ssh
      '';
    };
  };

  hmConfig = hmOpts: {
    home.packages = with pkgs; [
      diff-so-fancy
      git-crypt
      hub
      tig
    ];
    programs.gh = {
      enable = true;
      package = pkgs.gh;
      settings = {
        git_protocol = "ssh";
        prompt = "enabled";
        editor = "codium -w";
      };
    };
    programs.git = {
      enable = true;
      package = pkgs.git;
      signing = {
        key = "DABD05C1D9C1FD2A";
        signByDefault = true;
      };
      settings = {
        user = {
          name = "XiaoXioe";
          email = "169626976+XiaoXioe@users.noreply.github.com";
        };
        safe.directory = [
          "${hmOpts.config.home.homeDirectory}/nixos-config"
          "${hmOpts.config.home.homeDirectory}/nix-custompkgs-priv"
        ];
        init.defaultBranch = "main";
        push.autoSetupRemote = true;
        pull.rebase = true;
      };
    };
  };
}
