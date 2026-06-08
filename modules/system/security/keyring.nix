{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.system.security.keyring;
in
{
  options.my.system.security.keyring = {
    enable = lib.mkEnableOption "Keyring configuration" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable Polkit
    security.polkit.enable = true;

    # Enable GNOME Keyring
    services.gnome.gnome-keyring.enable = true;

    # For SDDM:
    security.pam.services.sddm.enableGnomeKeyring = true;

    environment.systemPackages = with pkgs; [
      # GUI for viewing and managing keyring contents
      seahorse

      # Polkit authentication agent (munculin pop-up password)
      polkit_gnome
    ];
  };
}
