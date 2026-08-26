{
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.office.onlyoffice";
  description = "OnlyOffice Desktop Editors office suite";

  hmConfig = {
    home.packages = [ (selfLib.fetchCachePinned "onlyoffice") ];
  };
}
