{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.my.system.desktop.greeter;
in
{

  options.my.system.desktop.greeter = {
    enable = lib.mkEnableOption "custom display manager greeter" // {
      default = true;
    };

    # Display manager backend selection
    backend = lib.mkOption {
      type = lib.types.enum [
        "dms"
        "sddm"
        "gdm"
      ];
      default = "sddm"; # Greeter bawaan jika tidak ditentukan
      description = "Pilih display manager yang ingin digunakan: dms, sddm, atau gdm.";
    };
  };

  config = lib.mkIf cfg.enable {

    # Package theme
    environment.systemPackages = [
      (pkgs.catppuccin-sddm.override {
        flavor = "mocha";
        accent = "mauve";
        font = "Noto Sans";
        fontSize = "9";
        loginBackground = true;
      })
    ];

    # Enable dms-greeter only when backend == "dms"
    services.displayManager.dms-greeter = lib.mkIf (cfg.backend == "dms") {
      enable = true;
      compositor.name = "niri";
    };

    # Enable SDDM only when backend == "sddm"
    services.displayManager.sddm = lib.mkIf (cfg.backend == "sddm") {
      enable = true;
      theme = "catppuccin-mocha-mauve";
      wayland.enable = true;
      # extraPackages = with pkgs; [
      #   kdePackages.qtmultimedia
      # ];
    };

    # Enable GDM only when backend == "gdm"
    services.displayManager.gdm.enable = (cfg.backend == "gdm");

    # Prevent black screen during rebuild by disabling automatic DM restart
    systemd.services.display-manager.restartIfChanged = false;

    hardware.i2c.enable = true;

  };
}
