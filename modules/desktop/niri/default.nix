{
  inputs,
  selfLib,
  lib,
  ...
}:

selfLib.mkModule {
  name = "desktop.niri";
  description = "Niri scrollable-tiling Wayland compositor";

  options = {
    dms = {
      enable = lib.mkEnableOption "DankMaterialShell for Niri";
    };
    noctalia = {
      enable = lib.mkEnableOption "Noctalia shell for Niri";
    };
  };

  imports = [
    inputs.niri.nixosModules.niri
    ./sessions.nix
  ];

  nixosConfig =
    { pkgs, config, ... }:
    {
      programs.niri.enable = true;
      programs.niri.package = pkgs.niri;

      # XDG Desktop Portal: Arahkan Inhibit interface ke 'none'
      # Memaksa Firefox/Zen Browser menggunakan protokol Wayland native zwp_idle_inhibit_manager_v1 di Niri
      xdg.portal = {
        enable = true;
        config = {
          common = {
            default = [ "gtk" ];
          };
          niri = {
            default = [
              "gnome"
              "gtk"
            ];
            "org.freedesktop.impl.portal.Inhibit" = [ "none" ];
          };
        };
      };

      # Auto-wire shell options to modular shells
      my.desktop.shells.dms.enable = lib.mkIf (config.my.desktop.niri.dms.enable or false) true;
      my.desktop.shells.noctalia.enable = lib.mkIf (config.my.desktop.niri.noctalia.enable or false) true;
    };

  hmConfig =
    { pkgs, ... }:
    {
      imports = selfLib.scanPaths ./settings;
      home.packages = with pkgs; [
        bemoji
        wtype
        fuzzel
        wayland-pipewire-idle-inhibit
      ];

      # Audio-aware idle inhibitor: Otomatis menahan layar idle saat ada suara aktif di PipeWire
      systemd.user.services.wayland-pipewire-idle-inhibit = {
        Unit = {
          Description = "Wayland idle inhibitor based on PipeWire audio stream";
          PartOf = [ "graphical-session.target" ];
          After = [
            "graphical-session.target"
            "pipewire.service"
          ];
        };
        Service = {
          ExecStart = "${pkgs.wayland-pipewire-idle-inhibit}/bin/wayland-pipewire-idle-inhibit -i wayland -d 5 -v WARN";
          Restart = "on-failure";
          RestartSec = "3s";
        };
        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };
    };
}
