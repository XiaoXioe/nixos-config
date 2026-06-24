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
  vpnDir = ../../secrets/vpn-files;
  vpnFiles = selfLib.getVpnFiles vpnDir;
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

      templates."cachix.dhall" = {
        path = "/home/${userName}/.config/cachix/cachix.dhall";
        owner = userName;
        mode = "0600";
        content = ''
          { authToken = "${config.sops.placeholder.cachix-token}" }
        '';
      };
    };

    sops.secrets = lib.mkMerge [
      # --- Static secrets ---
      {
        "ssh-user-klein" = {
          owner = userName;
          path = "/home/${config.my.user.name}/.ssh/id_ed25519";
          mode = "0600";
        };
        "ssh-rsa-user-klein" = {
          owner = userName;
          path = "/home/${config.my.user.name}/.ssh/id_rsa_compat";
          mode = "0600";
        };

        "fastfetch-logo" = {
          format = "binary";
          sopsFile = ../../secrets/binary/fastfetch-logo.enc;
          owner = userName;
          mode = "0444";
        };

        "foto-profile" = {
          format = "binary";
          owner = userName;
          sopsFile = ../../secrets/binary/foto-profile.enc;
        };

        "github-token" = {
          owner = userName;
          # Restart nix-daemon to reload the token on change
          restartUnits = [ "nix-daemon.service" ];
          mode = "0400";
        };

        "github-access-token" = {
          owner = userName;
          mode = "0400";
        };

        "gh_hosts_yml" = {
          owner = userName;
          path = "/home/${config.my.user.name}/.config/gh/hosts.yml";
          mode = "0600";
        };

        "ollama-env" = { };

        "cloudflare-token" = {
          owner = userName;
          mode = "0400";
        };

        "9router-env" = {
          # JWT_SECRET, INITIAL_PASSWORD — loaded as docker env-file
          mode = "0400";
        };

        "mt5-vnc-env" = {
          # VNC_PASSWORD — loaded as docker env-file
          mode = "0400";
        };

        "ninerouter-key" = {
          # API key from 9Router Dashboard → Keys
          # Digunakan CLI tools (Codex, Claude Code, dkk) sbg Authorization header
          owner = userName;
          mode = "0400";
        };

        "gemini-api-key" = {
          owner = userName;
        };

        "cachix-token" = {
          owner = userName;
        };

        "wg-lan.conf" = {
          sopsFile = ../../secrets/binary/wg-lan.enc.conf;
          format = "binary";
          path = "/etc/wireguard/wg-lan.conf";
          owner = "root";
          group = "root";
          mode = "600";
        };

        "wg-wifi.conf" = {
          sopsFile = ../../secrets/binary/wg-wifi.enc.conf;
          format = "binary";
          path = "/etc/wireguard/wg-wifi.conf";
          owner = "root";
          group = "root";
          mode = "600";
        };

        "rclone.conf" = {
          format = "binary";
          sopsFile = ../../secrets/binary/rclone.enc.conf;
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
        "${userName}_password_hash" = {
          neededForUsers = true;
          key = "klein-moretti_password_hash";
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
        "adbkey_${userName}" = {
          key = "adbkey";
          owner = userName;
          path = "/home/${userName}/.android/adbkey";
          mode = "0400";
        };

        "adbkey_pub_${userName}" = {
          key = "adbkey_pub";
          owner = userName;
          path = "/home/${userName}/.android/adbkey.pub";
          mode = "0444";
        };
      }
    ];

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
