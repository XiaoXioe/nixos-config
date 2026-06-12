{
  config,
  lib,
  pkgs,
  selfLib,
  ...
}:
let
  cfg = config.my.security.gnupg;
in
{
  options = selfLib.mkNestedEnable "security.gnupg";

  config = lib.mkIf cfg.enable {
    # Enable GPG Agent
    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryPackage = pkgs.pinentry-gnome3;
    };

    # Menginstal aplikasi GUI
    environment.systemPackages = with pkgs; [
      kdePackages.kleopatra
    ];
  };
}
