{
  config,
  lib,
  pkgs,
  selfLib,
  allUsers,
  ...
}:
let
  cfg = config.my.system.secrets;
  vpnDir = ../../../secrets/vpn-files;
  vpnFilesRaw = if builtins.pathExists vpnDir then builtins.readDir vpnDir else { };
  vpnFiles = builtins.filter (name: vpnFilesRaw.${name} == "regular" && lib.hasSuffix ".conf" name) (
    builtins.attrNames vpnFilesRaw
  );
in
{
  options.my.system.secrets = {
    enable = selfLib.mkBoolOpt false "Sops-nix secrets management";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      sops
    ];
    sops = {
      defaultSopsFile = ../../../secrets/secrets.yaml; # Sesuaikan path-nya dari file .nix ini
      defaultSopsFormat = "yaml";

      # Gunakan SSH key langsung sebagai age key:
      age.sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
      # age.keyFile = null;
      # age.generateKey = false;
    };

    sops.secrets = lib.mkMerge [
      # --- Konfigurasi Statis ---
      {

        # Ssh user keys
        "ssh-user-klein" = {
          owner = "klein-moretti";
          path = "/home/klein-moretti/.ssh/id_ed25519";
          mode = "0600";
        };

        # Fastfetch logo
        "fastfetch-logo" = {
          format = "binary";
          sopsFile = ../../../secrets/fastfetch-logo.enc;
          owner = "klein-moretti";
          mode = "0444";
        };

        # Photo profile user
        "foto-profile" = {
          format = "binary";
          owner = "klein-moretti";
          sopsFile = ../../../secrets/foto-profile.enc;
        };

        # Github acces token
        "github-token" = {
          owner = "klein-moretti";
          # Restart nix-daemon agar memuat ulang token setiap kali ada perubahan
          restartUnits = [ "nix-daemon.service" ];
          mode = "0400";
        };

        "garnix-netrc" = {
          owner = "root";
          group = "nixbld";
          mode = "0440";
        };

        "gh_hosts_yml" = {
          owner = "klein-moretti";
          path = "/home/klein-moretti/.config/gh/hosts.yml";
          mode = "0600";
        };

        # Ollama Keys
        "ollama-env" = {
          # owner = "ollama";
          # group = "ollama";
        };

        "gemini-api-key" = {
          owner = "klein-moretti";
        };

        # Wg-lan config
        "wg-lan.conf" = {
          sopsFile = ../../../secrets/wg-lan.enc.conf;
          format = "binary";
          path = "/etc/wireguard/wg-lan.conf";
          owner = "root";
          group = "root";
          mode = "600";
        };
        # Wg-wifi config
        "wg-wifi.conf" = {
          sopsFile = ../../../secrets/wg-wifi.enc.conf;
          format = "binary";
          path = "/etc/wireguard/wg-wifi.conf";
          owner = "root";
          group = "root";
          mode = "600";
        };

        # Rclone config
        "rclone.conf" = {
          # Beritahu sops-nix bahwa ini file binary (hasil enkripsi mentah)
          format = "binary";
          sopsFile = ../../../secrets/rclone.enc.conf;

          # Biarkan sops-nix menempatkannya di default path (/run/secrets/rclone.conf)
          # karena rclone butuh nulis ulang token, kita akan copy dari sana di rclone.nix
          owner = config.my.user.name;
          group = "users";
          mode = "0400";
        };

        # NextDNS Secrets
        "nextdns_stamp" = { };
        "nextdns_name" = { };
      }

      # --- Konfigurasi Hash Password Dinamis (Root + AllUsers) ---
      (lib.genAttrs (map (name: "${name}_password_hash") ([ "root" ] ++ builtins.attrNames allUsers))
        (_: {
          neededForUsers = true;
        })
      )

      # --- Konfigurasi VPN Dinamis ---
      (lib.genAttrs vpnFiles (fileName: {
        sopsFile = ../../../secrets/vpn-files/${fileName};
        format = "binary";
        owner = config.my.user.name;
        mode = "600";
      }))

      # --- Konfigurasi Dinamis (AllUsers) ---
      (selfLib.forAllUsers allUsers (
        userName: _: {

          # Otomatisasi ADB Key
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
    ]; # Tutup lib.mkMerge

    # Gunakan password dari sops untuk root dan semua allUsers langsung ke opsi native users.users
    users.users = lib.genAttrs ([ "root" ] ++ builtins.attrNames allUsers) (userName: {
      hashedPasswordFile = lib.mkForce config.sops.secrets."${userName}_password_hash".path;
    });
  };
}
