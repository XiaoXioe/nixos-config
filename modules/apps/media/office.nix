{
  selfLib,
  pkgs,
  lib,
  ...
}:

selfLib.mkModule {
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

  flatpakCfg = {
    "org.pwmt.zathura" = {
      enable = true;
      symlinks = [
        {
          host = ".local/share/zathura";
          guest = "data/zathura";
        }
      ];
      nativePkgs = pkgs.zathura;
    };

    "org.onlyoffice.desktopeditors" = {
      enable = true;
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
      nativePkgs = pkgs.onlyoffice-desktopeditors;
      hmProgram = {
        name = "onlyoffice";
        extraConfig = {
          settings = {
            UITheme = "theme-contrast-dark";
          };
        };
      };
    };
  };
}
