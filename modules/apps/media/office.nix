{
  selfLib,
  pkgs,
  lib,
  config,
  ...
}:

{
  imports = [
    (selfLib.mkModule {
      name = "apps.media.office";
      description = "Office applications bundle";
      options = {
        flatpak = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Whether to use Flatpak for all office applications by default.";
          };
        };
      };
    })

    (selfLib.mkApp {
      name = "apps.media.zathura";
      description = "Zathura Document Viewer";
      options = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = config.my.apps.media.office.enable;
          description = "Enable Zathura Document Viewer";
        };
        flatpak.enable = lib.mkOption {
          type = lib.types.bool;
          default = config.my.apps.media.office.flatpak.enable;
          description = "Whether to use Flatpak for Zathura instead of the native package.";
        };
      };
      flatpak = {
        appId = "org.pwmt.zathura";
        symlinks = [
          {
            host = ".local/share/zathura";
            guest = "data/zathura";
          }
        ];
      };
      native = {
        package = pkgs.zathura;
      };
    })

    (selfLib.mkApp {
      name = "apps.media.onlyoffice";
      description = "OnlyOffice Desktop Editors";
      options = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = config.my.apps.media.office.enable;
          description = "Enable OnlyOffice";
        };
        flatpak.enable = lib.mkOption {
          type = lib.types.bool;
          default = config.my.apps.media.office.flatpak.enable;
          description = "Whether to use Flatpak for OnlyOffice instead of the native package.";
        };
      };
      flatpak = {
        appId = "org.onlyoffice.desktopeditors";
        symlinks = [
          {
            host = ".config/onlyoffice";
            guest = "config/onlyoffice";
          }
          {
            host = ".local/share/onlyoffice";
            guest = "data/onlyoffice";
          }
        ];
      };
      native = {
        package = pkgs.onlyoffice-desktopeditors;
      };
      hmProgram = {
        name = "onlyoffice";
        extraConfig = {
          settings = {
            UITheme = "theme-contrast-dark";
          };
        };
      };
    })
  ];
}
