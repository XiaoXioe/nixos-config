{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:
selfLib.mkModule {
  name = "desktop.greeter";
  options = {
    backend = lib.mkOption {
      type = lib.types.enum [
        "dms"
        "sddm"
        "gdm"
      ];
      default = "sddm";
      description = "Pilih display manager yang ingin digunakan: dms, sddm, atau gdm.";
    };
  };

  nixosConfig =
    let
      cfg = config.my.desktop.greeter;
    in
    {
      environment.systemPackages = with pkgs; [
        (catppuccin-sddm.override {
          flavor = "mocha";
          accent = "mauve";
          font = "Noto Sans";
          fontSize = "9";
          loginBackground = true;
        })

        seahorse
        polkit_gnome
      ];

      services.displayManager.dms-greeter = lib.mkIf (cfg.backend == "dms") {
        enable = true;
        compositor.name = "niri";
      };

      services.displayManager.sddm = lib.mkIf (cfg.backend == "sddm") {
        enable = true;
        theme = "catppuccin-mocha-mauve";
        wayland.enable = true;
      };

      services.displayManager.gdm.enable = (cfg.backend == "gdm");

      systemd.services.display-manager.restartIfChanged = false;

      hardware.i2c.enable = true;
      security.polkit.enable = true;
      services.gnome.gnome-keyring.enable = true;
      security.pam.services.sddm.enableGnomeKeyring = true;
    };
}
