{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.desktop.greeter;
in
{
  options = selfLib.mkNestedEnable "desktop.greeter" // {
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

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      (pkgs.catppuccin-sddm.override {
        flavor = "mocha";
        accent = "mauve";
        font = "Noto Sans";
        fontSize = "9";
        loginBackground = true;
      })
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
  };
}
