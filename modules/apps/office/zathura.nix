{
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.office.zathura";
  description = "Zathura lightweight PDF and document reader with pure upstream binary";

  hmConfig = {
    home.packages = [ (selfLib.fetchCachePinned "zathura") ];
  };
}
