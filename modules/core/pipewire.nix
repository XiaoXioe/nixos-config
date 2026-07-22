# Basic PipeWire audio system.
{
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "core.pipewire";

  nixosConfig = {
    nixpkgs.overlays = [
      (final: prev: {
        pkgsi686Linux = prev.pkgsi686Linux.extend (
          self32: super32: {
            pipewire = super32.pipewire.override {
              libcamera = {
                meta.platforms = [ ];
              };
              ffadoSupport = false;
              rocSupport = false;
            };
          }
        );
      })
    ];

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
