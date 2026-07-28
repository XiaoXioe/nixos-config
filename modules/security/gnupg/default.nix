{
  config,
  lib,
  pkgs,
  selfLib,
  ...
}:

let
  gpgKeyNums = [
    "1"
    "2"
    "3"
  ];
  gpgKeyIds = {
    "1" = "DABD05C1D9C1FD2A";
    "2" = "B10004A433825F0F";
    "3" = "95217AF28DBCD5E3";
  };
in
selfLib.mkModule {
  name = "security.gnupg";

  nixosConfig = {
    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryPackage = pkgs.pinentry-gnome3;
      settings = {
        default-cache-ttl = 86400; # 24 Hours
        max-cache-ttl = 86400;
      };
    };

    sops.secrets = lib.listToAttrs (
      map (n: {
        name = "gpg-private-key-${n}";
        value = {
          format = "binary";
          sopsFile = selfLib.secretBinary "gnupg/private-key-${n}.enc";
          owner = config.my.user.name;
          mode = "0600";
        };
      }) gpgKeyNums
    );
  };

  hmConfig = hmOpts: {
    programs.gpg = {
      enable = true;
      publicKeys = map (n: {
        source = ./. + "/public-key-${n}.asc";
        trust = "ultimate";
      }) gpgKeyNums;
    };

    home.file =
      lib.listToAttrs (
        map (n: {
          name = ".gnupg/public-key-${n}.asc";
          value.source = ./. + "/public-key-${n}.asc";
        }) gpgKeyNums
      )
      // {
        ".gnupg/sshcontrol".text = ''
          # Managed by Home Manager
          05C43456D409B53584AE76A4EA71B1A8128E5E37
        '';
      };

    home.activation.importGpgPrivateKeys = hmOpts.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${lib.concatMapStringsSep "\n" (n: ''
        key_path="${hmOpts.osConfig.sops.secrets."gpg-private-key-${n}".path}"
        key_id="${gpgKeyIds.${n}}"
        if [ -f "$key_path" ]; then
          if ! ${pkgs.gnupg}/bin/gpg --list-secret-keys "$key_id" >/dev/null 2>&1; then
            echo "Importing GPG private key ${n} ($key_id)..."
            ${pkgs.gnupg}/bin/gpg --batch --import "$key_path" || true
          fi
        fi
      '') gpgKeyNums}
    '';
  };
}
