{
  config,
  flakePath,
  lib,
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.dev.ssh";
  description = "Ssh configuration";

  nixosConfig = {
    environment.etc."ssh/ssh_config".text = lib.mkForce ''
      Match host * exec "${pkgs.bashInteractive}/bin/bash -c '${pkgs.gnupg}/bin/gpg-connect-agent --quiet updatestartuptty /bye >/dev/null 2>&1'"
      Host *
      GlobalKnownHostsFile /etc/ssh/ssh_known_hosts
      AddressFamily inet
      ForwardX11 no
    '';
    systemd.tmpfiles.rules = [
      "d /home/${config.my.user.name}/.ssh 0700 ${config.my.user.name} users - -"
    ];
    sops.secrets = {
      "ssh-user-klein" = {
        format = "binary";
        sopsFile = selfLib.secretBinary "ssh-user-klein.enc";
        owner = config.my.user.name;
        path = "/home/${config.my.user.name}/.ssh/id_ed25519";
        mode = "0600";
      };
      "ssh-rsa-user-klein" = {
        format = "binary";
        sopsFile = selfLib.secretBinary "ssh-rsa-user-klein.enc";
        owner = config.my.user.name;
        path = "/home/${config.my.user.name}/.ssh/id_rsa_compat";
        mode = "0600";
      };
    };
  };

  hmConfig = hmOpts: {
    home.file.".ssh/config_raw".source =
      hmOpts.config.lib.file.mkOutOfStoreSymlink "${flakePath}/dotfiles/ssh-config/config.conf";
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      includes = [ "~/.ssh/config_raw" ];
      settings = {
        "*" = {
          SendEnv = "LANG LC_*";
        };
        "github.com" = {
          User = "git";
          IdentityFile = "~/.ssh/id_ed25519";
          IdentitiesOnly = "yes";
        };
      };
    };
  };
}
