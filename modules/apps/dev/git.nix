{
  config,
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.dev.git";
  description = "user git configuration";

  nixosConfig = {
    systemd.tmpfiles.rules = [
      "d /home/${config.my.user.name}/.config/gh 0700 ${config.my.user.name} users - -"
    ];
    sops.templates."gh-hosts.yml" = {
      path = "/home/${config.my.user.name}/.config/gh/hosts.yml";
      owner = config.my.user.name;
      mode = "0600";
      content = ''
        github.com:
            user: ${config.sops.placeholder.github-user-primary}
            users:
                ${config.sops.placeholder.github-user-primary}:
                    oauth_token: ${config.sops.placeholder.github-access-token-primary}
                    git_protocol: ssh
                ${config.sops.placeholder.github-user-secondary}:
                    oauth_token: ${config.sops.placeholder.github-access-token-secondary}
                    git_protocol: ssh
            oauth_token: ${config.sops.placeholder.github-access-token-primary}
            git_protocol: ssh
      '';
    };
    sops.secrets = {
      "github-user-primary" = {
        owner = config.my.user.name;
        mode = "0400";
      };
      "github-access-token-primary" = {
        owner = config.my.user.name;
        mode = "0400";
      };
      "github-user-secondary" = {
        owner = config.my.user.name;
        mode = "0400";
      };
      "github-access-token-secondary" = {
        owner = config.my.user.name;
        mode = "0400";
      };
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
    programs.gpg = {
      enable = true;
      publicKeys = [
        {
          source = ./public-key.asc;
          trust = "ultimate";
        }
      ];
    };
    home.file.".gnupg/public-key.asc".source = ./public-key.asc;
    home.file.".gnupg/sshcontrol".text = ''
      # Managed by Home Manager
      05C43456D409B53584AE76A4EA71B1A8128E5E37
    '';
    programs.git = {
      enable = true;
      package = pkgs.git;
      signing = {
        key = "DABD05C1D9C1FD2A";
        signByDefault = true;
      };
      settings = {
        user = {
          name = hmOpts.osConfig.my.user.fullName;
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
    home.activation.importGpg = hmOpts.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ -f ${hmOpts.osConfig.sops.secrets."gpg-private-key".path} ]; then
        if ! ${pkgs.gnupg}/bin/gpg --list-secret-keys | grep -q "DABD05C1D9C1FD2A"; then
          echo "Importing GPG private key..."
          ${pkgs.gnupg}/bin/gpg --import ${hmOpts.osConfig.sops.secrets."gpg-private-key".path}
        fi
      fi
    '';
  };
}
