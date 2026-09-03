{
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.office.zathura";
  description = "Zathura lightweight PDF and document reader with pure upstream binary";

  hmConfig = {
    programs.zathura = {
      enable = true;
      package = selfLib.fetchCachePinned "zathura";
      options = {
        selection-clipboard = "clipboard";
      };
    };
  };
}
