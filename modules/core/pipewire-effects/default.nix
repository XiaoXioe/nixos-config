# PipeWire audio effects — auto-imports all preset modules.
{ selfLib, ... }:
{
  imports = selfLib.scanPaths ./.;
}
