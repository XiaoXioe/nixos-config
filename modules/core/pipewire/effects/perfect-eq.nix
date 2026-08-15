{
  config,
  pkgs,
  selfLib,
  ...
}:
let
  eqFilters = [
    {
      type = "bq_highshelf";
      freq = 0;
      q = 1.0;
      gain = -2.0;
    }
    {
      type = "bq_peaking";
      freq = 32.0;
      q = 1.5048;
      gain = 4.0;
    }
    {
      type = "bq_peaking";
      freq = 64.0;
      q = 1.5048;
      gain = 2.0;
    }
    {
      type = "bq_peaking";
      freq = 125.0;
      q = 1.5048;
      gain = 1.0;
    }
    {
      type = "bq_peaking";
      freq = 250.0;
      q = 1.5048;
      gain = 0.0;
    }
    {
      type = "bq_peaking";
      freq = 500.0;
      q = 1.5048;
      gain = -1.0;
    }
    {
      type = "bq_peaking";
      freq = 1000.0;
      q = 1.5048;
      gain = -2.0;
    }
    {
      type = "bq_peaking";
      freq = 2000.0;
      q = 1.5048;
      gain = 0.0;
    }
    {
      type = "bq_peaking";
      freq = 4000.0;
      q = 1.5048;
      gain = 2.0;
    }
    {
      type = "bq_peaking";
      freq = 8000.0;
      q = 1.5048;
      gain = 3.0;
    }
    {
      type = "bq_peaking";
      freq = 16000.0;
      q = 1.5048;
      gain = 3.0;
    }
  ];

  renderedFilters = selfLib.mkEqFilterString eqFilters;

  filterChainConf = ''
    context.modules = [
      { name = libpipewire-module-filter-chain
        flags = [ nofail ]
        args = {
          node.description = "Perfect EQ"
          media.name       = "Perfect EQ"
          audio.channels   = 2
          audio.position   = [ FL FR ]
          capture.props = {
            node.name   = "effect_input.perfect_eq"
            media.class = Audio/Sink
            audio.channels = 2
            audio.position = [ FL FR ]
          }
          playback.props = {
            node.name   = "effect_output.perfect_eq"
            node.passive = true
            audio.channels = 2
            audio.position = [ FL FR ]
          }
          filter.graph = {
            nodes = [
              {
                type  = builtin
                name  = eq_left
                label = param_eq
                config = {
                  filters = [
                    ${renderedFilters}
                  ]
                }
              }
              {
                type  = builtin
                name  = eq_right
                label = param_eq
                config = {
                  filters = [
                    ${renderedFilters}
                  ]
                }
              }
            ]
            inputs  = [ "eq_left:In 1" "eq_right:In 1" ]
            outputs = [ "eq_left:Out 1" "eq_right:Out 1" ]
          }
        }
      }
    ]
  '';
in
selfLib.mkModule {
  name = "core.pipewire.pipewireEffects.perfectEq";

  nixosConfig = {
    assertions = [
      {
        assertion = config.services.pipewire.enable;
        message = "perfectEq requires services.pipewire.enable = true";
      }
    ];

    services.pipewire.configPackages = [
      (pkgs.writeTextDir "share/pipewire/pipewire.conf.d/50-perfect-eq.conf" filterChainConf)
    ];
  };
}
