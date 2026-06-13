{
  pkgs,
  selfLib,
  ...
}:
selfLib.mkModule {
  name = "security.keyring";

  nixosConfig = {
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
