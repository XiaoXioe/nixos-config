{
  config,
  pkgs,
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

    sops.secrets."gpg-private-key" = {
      owner = config.my.user.name;
      mode = "0600";
    };
  };
}
