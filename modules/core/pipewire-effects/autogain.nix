{
  config,
  lib,
  pkgs,
  selfLib,
  ...
}:
let
  cfg = config.my.core.pipewire.pipewireEffects.autogain;

  filterChainConf = ''
    context.modules = [
      { name = libpipewire-module-filter-chain
        flags = [ nofail ]
        args = {
          node.description = "Auto Gain"
          media.name       = "Auto Gain"
          audio.channels   = 2
          audio.position   = [ FL FR ]
          capture.props = {
            node.name   = "effect_input.autogain"
            media.class = Audio/Sink
            audio.channels = 2
            audio.position = [ FL FR ]
          }
          playback.props = {
            node.name   = "effect_output.autogain"
            node.passive = true
            audio.channels = 2
            audio.position = [ FL FR ]
          }
          filter.graph = {
            nodes = [
              {
                type  = builtin
                name  = autogain
                label = compand
                config = {
                  # compand = [ attack, decay, [ soft-knee ], threshold-dB, ratio, [ gain-dB ] ]
                  # ratio: 1.0 (no compression) to inf (limiting)
                  #
                  # - "soft" leveling (default)
                  compand = [ 0.2 0.8 0.0 -20.0 2.0 0.0 ]
                }
              }
            ]
          }
        }
      }
    ]
  '';
in
{
  options = selfLib.mkNestedEnable "core.pipewire.pipewireEffects.autogain";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.services.pipewire.enable;
        message = "autogain requires services.pipewire.enable = true";
      }
    ];

    services.pipewire.configPackages = [
      (pkgs.writeTextDir
        "share/pipewire/pipewire.conf.d/50-autogain.conf"
        filterChainConf
      )
    ];
  };
}
