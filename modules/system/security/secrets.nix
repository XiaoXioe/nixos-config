{
  config,
  lib,
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
    sops = {
      defaultSopsFile = ../../../secrets/secrets.yaml; # Sesuaikan path-nya dari file .nix ini
      defaultSopsFormat = "yaml";

      # Gunakan SSH key langsung sebagai age key:
      age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
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

        # Teldrive config
        "teldrive_config" = lib.mkIf (config.my.services.teldrive.enable or false) {
          # Path di mana aplikasi mengharapkan file konfigurasinya
          path = "/var/lib/teldrive/config.toml";

          # Atur izin akses agar aplikasi bisa membaca (misal: user teldrive)
          owner = "teldrive";
          group = "teldrive";
          mode = "0400";
        };

        # Github acces token
        "github-token" = {
          # owner = "root";
          # Restart nix-daemon agar memuat ulang token setiap kali ada perubahan
          restartUnits = [ "nix-daemon.service" ];
          # mode = "0400";
        };

        "gh_hosts_yml" = {
          owner = "klein-moretti";
          path = "/home/klein-moretti/.config/gh/hosts.yml";
          mode = "0600";
        };

        # Ollama Keys
        "ollama-env" = {
          owner = "root";
          mode = "600";
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
          mode = "0440"; # group "users" (termasuk "coba") perlu bisa membaca
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
