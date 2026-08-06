# Basic PipeWire audio system.
{
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "core.pipewire";

  nixosConfig = {

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    environment.sessionVariables = {
      PIPEWIRE_DEBUG = "1";
    };
  };
}
