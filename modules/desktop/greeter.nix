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
      default = "dms";
      description = "Pilih display manager yang ingin digunakan: dms, sddm, atau gdm.";
    };
  };

  nixosConfig =
    let
      cfg = config.my.desktop.greeter;
    in
    {
      environment.systemPackages =
        with pkgs;
        [
          seahorse
          polkit_gnome
        ]
        ++ lib.optional (cfg.backend == "sddm") (
          catppuccin-sddm.override {
            flavor = "mocha";
            accent = "mauve";
            font = "Noto Sans";
            fontSize = "9";
            loginBackground = true;
          }
        );

      services = {
        displayManager = {
          dms-greeter = lib.mkIf (cfg.backend == "dms") {
            enable = true;
            compositor.name = "niri";
          };

          sddm = lib.mkIf (cfg.backend == "sddm") {
            enable = true;
            theme = "catppuccin-mocha-mauve";
            wayland.enable = true;
          };

          gdm.enable = cfg.backend == "gdm";
        };

        gnome.gnome-keyring.enable = true;
      };

      systemd.services.display-manager.restartIfChanged = false;

      environment.variables = {

        NIXOS_OZONE_WL = "1";
      };

      hardware.i2c.enable = true;

      security = {
        polkit.enable = true;
        pam.services.sddm.enableGnomeKeyring = true;
      };
    };
}
