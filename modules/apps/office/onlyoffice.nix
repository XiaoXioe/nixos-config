{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.office.onlyoffice";
  description = "OnlyOffice Desktop Editors office suite";

  hmConfig = {
    home.packages = [ pkgs.onlyoffice-desktopeditors ];
  };
}
