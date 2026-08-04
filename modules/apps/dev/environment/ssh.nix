{
  config,
  flakePath,
  lib,
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.dev.environment.ssh";
  description = "Ssh configuration";

  preservation = {
    userDirectories = [
      {
        directory = ".ssh";
        mode = "0700";
      }
    ];
  };

  nixosConfig = {
    environment.etc."ssh/ssh_config".text = lib.mkForce ''
      Match host * exec "${pkgs.bashInteractive}/bin/bash -c '${pkgs.gnupg}/bin/gpg-connect-agent --quiet updatestartuptty /bye >/dev/null 2>&1'"
      Host *
      GlobalKnownHostsFile /etc/ssh/ssh_known_hosts
      AddressFamily inet
      ForwardX11 no
    '';
    sops.secrets = {
      "ssh-user-klein" = {
        format = "binary";
        sopsFile = ./secrets/ssh-user-klein.enc;
        owner = config.my.user.name;
        path = "/home/${config.my.user.name}/.ssh/id_ed25519";
        mode = "0600";
      };
      "ssh-rsa-user-klein" = {
        format = "binary";
        sopsFile = ./secrets/ssh-rsa-user-klein.enc;
        owner = config.my.user.name;
        path = "/home/${config.my.user.name}/.ssh/id_rsa_compat";
        mode = "0600";
      };
    };
  };

  hmConfig = hmOpts: {
    home.file = selfLib.mkHmSymlinks hmOpts.config {
      ".ssh/config" = "${flakePath}/dotfiles/ssh-config/config.conf";
    };
  };
}
