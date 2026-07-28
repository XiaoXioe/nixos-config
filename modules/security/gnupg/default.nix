{
  config,
  lib,
  pkgs,
  selfLib,
  ...
}:

let
  # Single Source of Truth untuk seluruh kunci GPG (Publik & Privat via sops)
  gpgKeysList = [
    {
      num = "1";
      id = "DABD05C1D9C1FD2A";
      pubFile = ./public-key-1.asc;
    }
    {
      num = "2";
      id = "B10004A433825F0F";
      pubFile = ./public-key-2.asc;
    }
    {
      num = "3";
      id = "95217AF28DBCD5E3";
      pubFile = ./public-key-3.asc;
    }
  ];
in
selfLib.mkModule {
  name = "security.gnupg";

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

    # Deklarasi rahasia kunci privat via sops-nix
    sops.secrets = lib.listToAttrs (
      map (key: {
        name = "gpg-private-key-${key.num}";
        value = {
          format = "binary";
          sopsFile = selfLib.secretBinary "gnupg/private-key-${key.num}.enc";
          owner = config.my.user.name;
          mode = "0600";
        };
      }) gpgKeysList
    );
  };

  hmConfig = hmOpts: {
    programs.gpg = {
      enable = true;
      # Impor kunci publik ke ring kunci GPG secara deklaratif
      publicKeys = map (key: {
        source = key.pubFile;
        trust = "ultimate";
      }) gpgKeysList;
    };

    home.file =
      lib.listToAttrs (
        map (key: {
          name = ".gnupg/public-key-${key.num}.asc";
          value.source = key.pubFile;
        }) gpgKeysList
      )
      // {
        ".gnupg/sshcontrol".text = ''
          # Managed by Home Manager
          05C43456D409B53584AE76A4EA71B1A8128E5E37
        '';
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
