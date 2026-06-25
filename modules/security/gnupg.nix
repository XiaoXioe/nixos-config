{
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
    };

  };
}
