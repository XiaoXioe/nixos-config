{
  selfLib,
  pkgs,
  ...
}:

selfLib.mkModule {
  name = "apps.office.onlyoffice";
  description = "OnlyOffice Desktop Editors office suite";

  flatpakCfg = {
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
