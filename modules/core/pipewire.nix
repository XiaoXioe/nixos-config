# Basic PipeWire audio system.
{
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "core.pipewire";

  nixosConfig = {

    boot.extraModprobeConfig = ''
      options snd_hda_intel power_save=0 power_save_controller=N
      options snd_hda_codec_realtek power_save=0
    '';

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;

      wireplumber.extraConfig."99-disable-suspend" = {
        "monitor.alsa.rules" = [
          {
            matches = [
              { "node.name" = "~alsa_input.*"; }
              { "node.name" = "~alsa_output.*"; }
            ];
            actions = {
              update-props = {
                "session.suspend-timeout-seconds" = 0;
              };
            };
          }
        ];
      };
    };

    environment.sessionVariables = {
      PIPEWIRE_DEBUG = "1";
    };
  };
}
