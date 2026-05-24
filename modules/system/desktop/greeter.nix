{
  config,
  pkgs,
  pkgsUnstable,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.system.greeter;
in
{

  options.my.system.greeter = {
    enable = selfLib.mkBoolOpt false "Aktifkan sistem Greeter kustom";

    # Tambahkan opsi 'backend' untuk memilih display manager
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

    # Aktifkan dms-greeter HANYA jika backend == "dms"
    # services.displayManager.dms-greeter = lib.mkIf (cfg.backend == "dms") {
    #   enable = true;
    #   compositor.name = "niri";
    # };

    # Aktifkan SDDM HANYA jika backend == "sddm"
    services.displayManager.sddm = lib.mkIf (cfg.backend == "sddm") {
      enable = true;
      theme = "catppuccin-mocha-mauve";
      wayland.enable = true;
      # extraPackages = with pkgs; [
      #   kdePackages.qtmultimedia
      # ];
    };

    # Aktifkan GDM HANYA jika backend == "gdm"
    services.displayManager.gdm.enable = (cfg.backend == "gdm");

    # Cegah layar hitam saat rebuild dengan menonaktifkan restart otomatis pada display manager
    systemd.services.display-manager.restartIfChanged = false;

    hardware.i2c.enable = true;

  };
}
