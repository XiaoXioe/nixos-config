{
  config,
  pkgs,
  inputs,
  selfLib,
  ...
}:

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

    sops.secrets."gpg-private-key-1" = {
      format = "binary";
      sopsFile = selfLib.secretBinary "private-key-1.enc";
      owner = config.my.user.name;
      mode = "0600";
    };
    sops.secrets."gpg-private-key-2" = {
      format = "binary";
      sopsFile = selfLib.secretBinary "private-key-2.enc";
      owner = config.my.user.name;
      mode = "0600";
    };
    sops.secrets."gpg-private-key-3" = {
      format = "binary";
      sopsFile = selfLib.secretBinary "private-key-3.enc";
      owner = config.my.user.name;
      mode = "0600";
    };
  };

  hmConfig = hmOpts: {
    programs.gpg = {
      enable = true;
      publicKeys = [
        {
          source = ./public-key-1.asc;
          trust = "ultimate";
        }
        {
          source = ./public-key-2.asc;
          trust = "ultimate";
        }
        {
          source = ./public-key-3.asc;
          trust = "ultimate";
        }
      ];
    };

    home.file.".gnupg/public-key-1.asc".source = ./public-key-1.asc;
    home.file.".gnupg/public-key-2.asc".source = ./public-key-2.asc;
    home.file.".gnupg/public-key-3.asc".source = ./public-key-3.asc;

    home.file.".gnupg/sshcontrol".text = ''
      # Managed by Home Manager
      05C43456D409B53584AE76A4EA71B1A8128E5E37
    '';

    home.activation.importGpg = hmOpts.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ -f ${hmOpts.osConfig.sops.secrets."gpg-private-key-1".path} ]; then
        if ! ${pkgs.gnupg}/bin/gpg --list-secret-keys | grep -q "DABD05C1D9C1FD2A"; then
          echo "Importing GPG private key 1..."
          ${pkgs.gnupg}/bin/gpg --import ${hmOpts.osConfig.sops.secrets."gpg-private-key-1".path}
        fi
      fi
      if [ -f ${hmOpts.osConfig.sops.secrets."gpg-private-key-2".path} ]; then
        if ! ${pkgs.gnupg}/bin/gpg --list-secret-keys | grep -q "B10004A433825F0F"; then
          echo "Importing GPG private key 2..."
          ${pkgs.gnupg}/bin/gpg --import ${hmOpts.osConfig.sops.secrets."gpg-private-key-2".path}
        fi
      fi
      if [ -f ${hmOpts.osConfig.sops.secrets."gpg-private-key-3".path} ]; then
        if ! ${pkgs.gnupg}/bin/gpg --list-secret-keys | grep -q "95217AF28DBCD5E3"; then
          echo "Importing GPG private key 3..."
          ${pkgs.gnupg}/bin/gpg --import ${hmOpts.osConfig.sops.secrets."gpg-private-key-3".path}
        fi
      fi
    '';
  };
}
