{
  selfLib,
  lib,
  ...
}:

{
  imports = (selfLib.scanPaths ./.) ++ [ ];
}
