{
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "services.boot-speedup";

  nixosConfig = {
    imports = selfLib.scanPaths ./.;
  };
}
