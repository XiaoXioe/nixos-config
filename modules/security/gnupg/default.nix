{
  config,
  lib,
  pkgs,
  selfLib,
  ...
}:

let
  # Single Source of Truth untuk seluruh kunci GPG (Publik, Privat & Keygrip via sops)
  gpgKeysList = [
    {
      num = "1";
      id = "DABD05C1D9C1FD2A";
      pubFile = ./public-key-1.asc;
      keygrip = "91650243647D9391B58D1A7A1FB83312EA6F54D0";
      extraKeygrips = [ "05C43456D409B53584AE76A4EA71B1A8128E5E37" ];
    }
    {
      num = "2";
      id = "B10004A433825F0F";
      pubFile = ./public-key-2.asc;
      keygrip = "8C439498A77B2A603D4F5ED3B33A810C64798A01";
      extraKeygrips = [ ];
    }
    {
      num = "3";
      id = "95217AF28DBCD5E3";
      pubFile = ./public-key-3.asc;
      keygrip = "9115CC1A76F2D4A9D9FA78ADDBE8119AE1E04F99";
      extraKeygrips = [ ];
    }
  ];
in
selfLib.mkModule {
  name = "security.gnupg";

  preservation = {
    userDirectories = [
      {
        directory = ".gnupg";
        mode = "0700";
      }
    ];
  };

  nixosConfig = {
    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryPackage = pkgs.pinentry-gnome3;
      settings = {
        default-cache-ttl = 86400; # 24 Jam
        max-cache-ttl = 86400;
      };
    };

    # Deklarasi rahasia kunci privat & passphrase per kunci via sops-nix
    sops.secrets = lib.mkMerge [
      (lib.listToAttrs (
        map (key: {
          name = "gpg-passphrase-${key.num}";
          value = {
            sopsFile = ./secrets.yaml;
            owner = config.my.user.name;
            mode = "0400";
          };
        }) gpgKeysList
      ))
      (lib.listToAttrs (
        map (key: {
          name = "gpg-private-key-${key.num}";
          value = {
            format = "binary";
            sopsFile = ./secrets + "/private-key-${key.num}.enc";
            owner = config.my.user.name;
            mode = "0600";
          };
        }) gpgKeysList
      ))
    ];
  };

  hmConfig = hmOpts: {
    services.gpg-agent = {
      enable = true;
      enableSshSupport = true;
      sshKeys = [ "05C43456D409B53584AE76A4EA71B1A8128E5E37" ];
      extraConfig = "allow-preset-passphrase";
    };

    programs.gpg = {
      enable = true;
      # Impor kunci publik ke ring kunci GPG secara deklaratif
      publicKeys = map (key: {
        source = key.pubFile;
        trust = "ultimate";
      }) gpgKeysList;
    };

    home.file = lib.listToAttrs (
      map (key: {
        name = ".gnupg/public-key-${key.num}.asc";
        value.source = key.pubFile;
      }) gpgKeysList
    );

    systemd.user.services.gpg-preset-passphrase = {
      Unit = {
        Description = "Preset GPG key passphrases into gpg-agent cache on startup";
        After = [ "gpg-agent.service" ];
        Wants = [ "gpg-agent.service" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${selfLib.mkApp pkgs "gpg-preset-passphrase"
          ''
            ${lib.concatMapStringsSep "\n" (key: ''
              pass_file="${hmOpts.osConfig.sops.secrets."gpg-passphrase-${key.num}".path}"
              if [ -f "$pass_file" ]; then
                # Gunakan stdin pipe agar passphrase TIDAK terekspos di /proc/<pid>/cmdline
                ${pkgs.gnupg}/libexec/gpg-preset-passphrase --preset ${key.keygrip} < "$pass_file" || true
                ${lib.concatMapStringsSep "\n" (extraGrip: ''
                  ${pkgs.gnupg}/libexec/gpg-preset-passphrase --preset ${extraGrip} < "$pass_file" || true
                '') key.extraKeygrips}
              fi
            '') gpgKeysList}
          ''
          [
            pkgs.gnupg
            pkgs.coreutils
          ]
        }";
      };
      Install = {
        WantedBy = [
          "graphical-session.target"
          "default.target"
        ];
      };
    };

    # KRUSIAL: home.activation Diperlukan untuk Mengimpor Kunci Privat GPG dari sops-nix ke Keyring Daemon GPG.
    # `programs.gpg.publicKeys` HANYA mengimpor kunci publik (.asc).
    # Kunci privat yang didekripsi oleh sops-nix di /run/user/1000/secrets/ HARUS diimpor secara eksplisit
    # ke dalam keyring rahasia GPG (~/.gnupg/private-keys-v1.d/) agar gpg/git commit -S dapat bekerja.
    home.activation.importGpgPrivateKeys = hmOpts.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${lib.concatMapStringsSep "\n" (key: ''
        key_path="${hmOpts.osConfig.sops.secrets."gpg-private-key-${key.num}".path}"
        key_id="${key.id}"
        if [ -f "$key_path" ]; then
          if ! ${pkgs.gnupg}/bin/gpg --list-secret-keys "$key_id" >/dev/null 2>&1; then
            echo "Importing GPG private key ${key.num} ($key_id)..."
            ${pkgs.gnupg}/bin/gpg --batch --import "$key_path" || true
          fi
        fi
      '') gpgKeysList}
    '';
  };
}
