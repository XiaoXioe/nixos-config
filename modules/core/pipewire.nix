# Basic PipeWire audio system.
{
  config,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.core.pipewire;
in
{
  options = selfLib.mkNestedEnable "core.pipewire";

  config = lib.mkIf cfg.enable {
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };
}
