{
  config,
  lib,
  pkgs,
  selfLib,
  ...
}:
let
  cfg = config.my.system.gnupg;
in
{
  options.my.system.gnupg = {
    enable = selfLib.mkBoolOpt false "Gnupg Tools";
  };

  config = lib.mkIf cfg.enable {
    # Mengaktifkan GPG Agent
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
