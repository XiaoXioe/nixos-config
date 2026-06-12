{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.media.office";
  description = "Office Apps for users";

  hmConfig = {
    home.packages = with pkgs; [ zathura libreoffice ];
    programs.onlyoffice = {
      enable = true;
      settings = { UITheme = "theme-contrast-dark"; };
    };
  };
}
