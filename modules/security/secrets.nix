# Sops-nix secrets management: SSH keys, API tokens, VPN configs, passwords.
{
  config,
  lib,
  pkgs,
  selfLib,
  ...
}:
let
  vpnDir = ../../secrets/vpn-files;
  vpnFilesRaw = if builtins.pathExists vpnDir then builtins.readDir vpnDir else { };
  vpnFiles = builtins.filter (name: vpnFilesRaw.${name} == "regular" && lib.hasSuffix ".conf" name) (
    builtins.attrNames vpnFilesRaw
  );
in
selfLib.mkModule {
  name = "security.secrets";

  nixosConfig = {
    environment.systemPackages = with pkgs; [
      sops
    ];
    sops = {
      defaultSopsFile = ../../secrets/secrets.yaml;
      defaultSopsFormat = "yaml";

      # Use the SSH host key as the age decryption key
      age.sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
    };

    sops.secrets = lib.mkMerge [
      # --- Static secrets ---
      {
        "ssh-user-klein" = {
          owner = "klein-moretti";
          path = "/home/${config.my.user.name}/.ssh/id_ed25519";
          mode = "0600";
        };
        "ssh-rsa-user-klein" = {
          owner = "klein-moretti";
          path = "/home/${config.my.user.name}/.ssh/id_rsa_compat";
          mode = "0600";
        };

        "fastfetch-logo" = {
          format = "binary";
          sopsFile = ../../secrets/binary/fastfetch-logo.enc;
          owner = "klein-moretti";
          mode = "0444";
        };

        "foto-profile" = {
          format = "binary";
          owner = "klein-moretti";
          sopsFile = ../../secrets/binary/foto-profile.enc;
        };

        "github-token" = {
          owner = "klein-moretti";
          # Restart nix-daemon to reload the token on change
          restartUnits = [ "nix-daemon.service" ];
          mode = "0400";
        };

        "gh_hosts_yml" = {
          owner = "klein-moretti";
          path = "/home/${config.my.user.name}/.config/gh/hosts.yml";
          mode = "0600";
        };

        "ollama-env" = { };

        "9router-env" = {
          # JWT_SECRET, INITIAL_PASSWORD — loaded as docker env-file
          mode = "0400";
        };

        "ninerouter-key" = {
          # API key from 9Router Dashboard → Keys
          # Digunakan CLI tools (Codex, Claude Code, dkk) sbg Authorization header
          owner = "klein-moretti";
          mode = "0400";
        };

        "gemini-api-key" = {
          owner = "klein-moretti";
        };

        "wg-lan.conf" = {
          sopsFile = ../../secrets/wg-lan.enc.conf;
          format = "binary";
          path = "/etc/wireguard/wg-lan.conf";
          owner = "root";
          group = "root";
          mode = "600";
        };

        "wg-wifi.conf" = {
          sopsFile = ../../secrets/wg-wifi.enc.conf;
          format = "binary";
          path = "/etc/wireguard/wg-wifi.conf";
          owner = "root";
          group = "root";
          mode = "600";
        };

        # Rclone config — placed at /run/secrets/rclone.conf,
        # then copied to ~/.config/rclone/ by rclone.nix at activation.
        # Made readable by the 'users' group so any user with rclone enabled can copy it.
        "rclone.conf" = {
          format = "binary";
          sopsFile = ../../secrets/rclone.enc.conf;
          # We don't set an explicit owner so root owns it,
          # but we give the 'users' group read access.
          group = "users";
          mode = "0440";
        };

        "nextdns_stamp" = { };
        "nextdns_name" = { };
      }

      # --- Password hashes (root + klein-moretti) ---
      {
        "root_password_hash" = {
          neededForUsers = true;
        };
        "klein-moretti_password_hash" = {
          neededForUsers = true;
        };
      }

      # --- Dynamic VPN configs ---
      (lib.genAttrs vpnFiles (fileName: {
        sopsFile = ../../secrets/vpn-files/${fileName};
        format = "binary";
        owner = config.my.user.name;
        mode = "600";
      }))

      # --- Per-user secrets (klein-moretti) ---
      {
        "adbkey_klein-moretti" = {
          key = "adbkey";
          owner = "klein-moretti";
          path = "/home/klein-moretti/.android/adbkey";
          mode = "0400";
        };

        "adbkey_pub_klein-moretti" = {
          key = "adbkey_pub";
          owner = "klein-moretti";
          path = "/home/klein-moretti/.android/adbkey.pub";
          mode = "0444";
        };
      }
    ];

    # Bind sops password hashes to users
    users.users = {
      root = {
        hashedPasswordFile = lib.mkForce config.sops.secrets."root_password_hash".path;
      };
      klein-moretti = {
        hashedPasswordFile = lib.mkForce config.sops.secrets."klein-moretti_password_hash".path;
      };
    };
  };
}
