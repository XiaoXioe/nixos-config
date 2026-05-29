{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.system.gnupg;
in
{
  options.my.system.gnupg = {
    enable = lib.mkEnableOption "Gnupg Tools";
  };

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
