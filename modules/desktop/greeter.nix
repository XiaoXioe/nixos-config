{
  config,
  lib,
  pkgs,
  selfLib,
  ...
}:
selfLib.mkModule {
  name = "desktop.greeter";

  preservation = {
    persist = true;
    directories = [
      "/var/lib/sddm"
      "/var/lib/dms-greeter"
    ];
  };

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
      environment.systemPackages = [
        (selfLib.fetchCachePinned "seahorse")
        pkgs.polkit_gnome
      ]
      ++ lib.optional (cfg.backend == "sddm" || cfg.backend == "gdm") pkgs.vimix-cursors
      ++ lib.optional (cfg.backend == "sddm" || cfg.backend == "gdm") (
        pkgs.writeTextFile {
          name = "default-cursor-theme";
          destination = "/share/icons/default/index.theme";
          text = ''
            [Icon Theme]
            Inherits=Vimix-white-cursors
          '';
        }
      )
      ++ lib.optional (cfg.backend == "sddm") pkgs.sddm-astronaut;

      services = {
        displayManager = {
          dms-greeter = lib.mkIf (cfg.backend == "dms") {
            enable = true;
            compositor.name = "niri";
            configHome = "/home/${config.my.user.name}";
          };

          sddm = lib.mkIf (cfg.backend == "sddm") {
            enable = true;
            theme = "sddm-astronaut-theme";
            wayland.enable = true;
            wayland.compositor = "kwin";
            extraPackages = with pkgs; [
              kdePackages.qtmultimedia # Required for video backgrounds/audio
            ];
            settings = {
              Theme = {
                CursorTheme = "Vimix-white-cursors";
              };
            };
          };

          gdm = lib.mkIf (cfg.backend == "gdm") {
            enable = true;
            settings = {
              org.gnome.desktop.interface.cursor-theme = "Vimix-white-cursors";
            };
          };
        };

        gnome.gnome-keyring.enable = true;
      };

      systemd.services.display-manager.restartIfChanged = false;

      environment.variables = {
        NIXOS_OZONE_WL = "1";
        XCURSOR_THEME = "Vimix-white-cursors";
        XCURSOR_SIZE = "24";
      };

      systemd.user.services.xdg-desktop-portal = {
        environment = {
          PATH = lib.mkForce "/run/wrappers/bin:/home/${config.my.user.name}/.nix-profile/bin:/etc/profiles/per-user/${config.my.user.name}/bin:/run/current-system/sw/bin";
        };
        serviceConfig = {
          StandardError = "null";
        };
      };

      security = {
        polkit.enable = true;
        pam.services.sddm.enableGnomeKeyring = true;
      };
    };
}
