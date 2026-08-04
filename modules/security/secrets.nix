# Sops-nix secrets management: SSH keys, API tokens, VPN configs, passwords.
{
  config,
  lib,
  pkgs,
  selfLib,
  ...
}:
let
  userName = config.my.user.name;
in
selfLib.mkModule {
  name = "security.secrets";

  preservation = {
    userDirectories = [
      {
        directory = ".ssh";
        mode = "0700";
      }
    ];
  };

  nixosConfig = {
    environment.systemPackages = with pkgs; [
      sops
    ];

    sops = {
      defaultSopsFile = ./secrets.yaml;
      defaultSopsFormat = "yaml";

      # Use the SSH host key as the age decryption key
      age.sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
    };

    sops.secrets = {
      "root_password_hash" = {
        neededForUsers = true;
      };
      "${userName}_password_hash" = {
        neededForUsers = true;
        key = "klein-moretti_password_hash";
      };
    };

    # Bind sops password hashes to users
    users.users = {
      root = {
        hashedPasswordFile = lib.mkForce config.sops.secrets."root_password_hash".path;
      };
      ${userName} = {
        hashedPasswordFile = lib.mkForce config.sops.secrets."${userName}_password_hash".path;
      };
    };
  };
}
