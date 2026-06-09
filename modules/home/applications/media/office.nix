{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.my.user.apps.media.office;
in
{
  options.my.user.apps.media.office = {
    enable = lib.mkEnableOption "Office Apps for users";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      # gimp
      zathura
      libreoffice
      # kdePackages.kdenlive
      # protonmail-desktop
    ];

    programs.onlyoffice = {
      enable = true;
      settings = {
        UITheme = "theme-contrast-dark";
      };
    };
  };
}
