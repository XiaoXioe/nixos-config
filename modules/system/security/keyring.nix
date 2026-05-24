{
  config,
  lib,
  pkgs,
  selfLib,
  ...
}:
let
  cfg = config.my.system.keyring;
in
{
  options.my.system.keyring = {
    enable = selfLib.mkBoolOpt false "Keyring configuration";
  };

  config = lib.mkIf cfg.enable {
    # Mengaktifkan Polkit
    security.polkit.enable = true;

    # Mengaktifkan GNOME Keyring
    services.gnome.gnome-keyring.enable = true;

    # Jika menggunakan SDDM:
    security.pam.services.sddm.enableGnomeKeyring = true;

    environment.systemPackages = with pkgs; [
      # GUI untuk melihat dan mengelola isi keyring
      seahorse

      # Polkit authentication agent (munculin pop-up password)
      polkit_gnome
    ];
  };
}
