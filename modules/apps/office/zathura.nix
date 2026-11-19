{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.office.zathura";
  description = "Zathura lightweight PDF and document reader";

  hmConfig = {
    programs.zathura = {
      enable = true;
      package = pkgs.zathura;
      options = {
        selection-clipboard = "clipboard";
      };
    };
  };
}
