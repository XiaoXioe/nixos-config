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

    systemd.user.services.pipewire-pulse = {
      environment = {
        PIPEWIRE_DEBUG = "1";
      };
    };
  };
}
