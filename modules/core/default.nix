{ selfLib, ... }:
{
  imports = (selfLib.scanPaths ./.) ++ [
    # ./pipewire-effects
  ];
}
