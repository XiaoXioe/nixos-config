{
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "services.boot-speedup";

  imports = selfLib.scanPaths ./.;
}
