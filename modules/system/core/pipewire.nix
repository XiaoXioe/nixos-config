# Basic PipeWire audio system.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.system.core.pipewire;
in
{
  options.my.system.core.pipewire = {
    enable = lib.mkEnableOption "PipeWire audio system";
  };

  config = lib.mkIf cfg.enable {
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };
}
