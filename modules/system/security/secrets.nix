# Sops-nix secrets management: SSH keys, API tokens, VPN configs, passwords.
{
  config,
  lib,
  pkgs,
  selfLib,
  allUsers,
  ...
}:
let
  cfg = config.my.system.security.secrets;
  vpnDir = ../../../secrets/vpn-files;
  vpnFilesRaw = if builtins.pathExists vpnDir then builtins.readDir vpnDir else { };
  vpnFiles = builtins.filter (name: vpnFilesRaw.${name} == "regular" && lib.hasSuffix ".conf" name) (
    builtins.attrNames vpnFilesRaw
  );
in
{
  options.my.system.security.secrets = {
    enable = lib.mkEnableOption "sops-nix secrets management";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      sops
    ];
    sops = {
      defaultSopsFile = ../../../secrets/secrets.yaml;
      defaultSopsFormat = "yaml";

      # Use the SSH host key as the age decryption key
      age.sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
    };

    sops.secrets = lib.mkMerge [
      # --- Static secrets ---
      {
        "ssh-user-klein" = {
          owner = "klein-moretti";
          path = "/home/klein-moretti/.ssh/id_ed25519";
          mode = "0600";
        };
        "ssh-rsa-user-klein" = {
          owner = "klein-moretti";
          path = "/home/klein-moretti/.ssh/id_rsa_compat";
          mode = "0600";
        };

        "fastfetch-logo" = {
          format = "binary";
          sopsFile = ../../../secrets/fastfetch-logo.enc;
          owner = "klein-moretti";
          mode = "0444";
        };

        "foto-profile" = {
          format = "binary";
          owner = "klein-moretti";
          sopsFile = ../../../secrets/foto-profile.enc;
        };

        "github-token" = {
          owner = "klein-moretti";
          # Restart nix-daemon to reload the token on change
          restartUnits = [ "nix-daemon.service" ];
          mode = "0400";
        };

        "gh_hosts_yml" = {
          owner = "klein-moretti";
          path = "/home/klein-moretti/.config/gh/hosts.yml";
          mode = "0600";
        };

        "ollama-env" = { };

        "gemini-api-key" = {
          owner = "klein-moretti";
        };

        "wg-lan.conf" = {
          sopsFile = ../../../secrets/wg-lan.enc.conf;
          format = "binary";
          path = "/etc/wireguard/wg-lan.conf";
          owner = "root";
          group = "root";
          mode = "600";
        };

        "wg-wifi.conf" = {
          sopsFile = ../../../secrets/wg-wifi.enc.conf;
          format = "binary";
          path = "/etc/wireguard/wg-wifi.conf";
          owner = "root";
          group = "root";
          mode = "600";
        };

        # Rclone config — placed at /run/secrets/rclone.conf,
        # then copied to ~/.config/rclone/ by rclone.nix at activation.
        "rclone.conf" = {
          format = "binary";
          sopsFile = ../../../secrets/rclone.enc.conf;
          owner = "klein-moretti";
          group = "users";
          mode = "0400";
        };

        "nextdns_stamp" = { };
        "nextdns_name" = { };
      }

      # --- Dynamic password hashes (root + all users) ---
      (lib.genAttrs (map (name: "${name}_password_hash") ([ "root" ] ++ builtins.attrNames allUsers))
        (_: {
          neededForUsers = true;
        })
      )

      # --- Dynamic VPN configs ---
      (lib.genAttrs vpnFiles (fileName: {
        sopsFile = ../../../secrets/vpn-files/${fileName};
        format = "binary";
        owner = config.my.user.name;
        mode = "600";
      }))

      # --- Per-user dynamic secrets ---
      (selfLib.forAllUsers allUsers (
        userName: _: {
          # ADB key pair (auto-provisioned per user)
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
      ))
    ];

    # Bind sops password hashes to users.users declaratively
    users.users = lib.genAttrs ([ "root" ] ++ builtins.attrNames allUsers) (userName: {
      hashedPasswordFile = lib.mkForce config.sops.secrets."${userName}_password_hash".path;
    });
  };
}
