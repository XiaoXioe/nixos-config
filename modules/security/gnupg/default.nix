{
  config,
  lib,
  pkgs,
  inputs,
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
        default-cache-ttl = 86400; # Cache selama 24 jam sejak terakhir aktif
        max-cache-ttl = 86400; # Maksimum cache 24 jam
      };
    };

    sops.secrets = lib.listToAttrs (
      map (
        n:
        lib.nameValuePair "gpg-private-key-${n}" {
          format = "binary";
          sopsFile = selfLib.secretBinary "gnupg/private-key-${n}.enc";
          owner = config.my.user.name;
          mode = "0600";
        }
      ) gpgKeyNums
    );
  };

  hmConfig =
    hmOpts:
    let
      gpgKeys = lib.genAttrs gpgKeyNums (n: {
        path = hmOpts.osConfig.sops.secrets."gpg-private-key-${n}".path;
        keyId = gpgKeyIds.${n};
      });
    in
    {
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

      home.activation.importGpg = hmOpts.lib.hm.dag.entryAfter [ "writeBoundary" ] (
        hmOpts.lib.concatStringsSep "\n" (
          hmOpts.lib.mapAttrsToList (num: key: ''
            if [ -f ${key.path} ]; then
              if ! ${pkgs.gnupg}/bin/gpg --list-secret-keys | grep -q "${key.keyId}"; then
                echo "Importing GPG private key ${num}..."
                ${pkgs.gnupg}/bin/gpg --import ${key.path}
              fi
            fi
          '') gpgKeys
        )
      );
    };
}
