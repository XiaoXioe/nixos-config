{
  config,
  lib,
  pkgs,
  selfLib,
  ...
}:
let
  eqFilters = [
    # input-gain  = -0.3 dB → preamp via highshelf at 0 Hz
    {
      type = "bq_highshelf";
      freq = 0;
      q = 1.0;
      gain = -0.3;
    }
    # band7–band12: +4 dB boost (113–358 Hz)
    {
      type = "bq_peaking";
      freq = 113.21;
      q = 4.36;
      gain = 4.0;
    }
    {
      type = "bq_peaking";
      freq = 142.53;
      q = 4.36;
      gain = 4.0;
    }
    {
      type = "bq_peaking";
      freq = 179.43;
      q = 4.36;
      gain = 4.0;
    }
    {
      type = "bq_peaking";
      freq = 225.89;
      q = 4.36;
      gain = 4.0;
    }
    {
      type = "bq_peaking";
      freq = 284.38;
      q = 4.36;
      gain = 4.0;
    }
    {
      type = "bq_peaking";
      freq = 358.02;
      q = 4.36;
      gain = 4.0;
    }
    # band15–band19: various cuts (714–1794 Hz)
    {
      type = "bq_peaking";
      freq = 714.34;
      q = 4.36;
      gain = -1.0;
    }
    {
      type = "bq_peaking";
      freq = 899.29;
      q = 4.36;
      gain = -2.0;
    }
    {
      type = "bq_peaking";
      freq = 1132.15;
      q = 4.36;
      gain = -3.6;
    }
    {
      type = "bq_peaking";
      freq = 1425.29;
      q = 4.36;
      gain = -2.5;
    }
    {
      type = "bq_peaking";
      freq = 1794.33;
      q = 4.36;
      gain = -1.5;
    }
    # output-gain = -6.5 dB → postamp via highshelf at 0 Hz
    {
      type = "bq_highshelf";
      freq = 0;
      q = 1.0;
      gain = -6.5;
    }
  ];

  renderFilter =
    f:
    "{ type = ${f.type}, freq = ${toString f.freq}, q = ${toString f.q}, gain = ${toString f.gain} }";

  renderedFilters = lib.concatMapStringsSep "\n                    " renderFilter eqFilters;

  # Port symbols verified with lv2info against installed plugin versions:
  #   Calf Exciter:      in_l, in_r, out_l, out_r, amount, drive, blend, freq, ceil, ceil_active, listen, level_in, level_out
  #   LSP Limiter Stereo: in_l, in_r, out_l, out_r, mode, th, boost, lk, at, rt, slink, g_in, g_out
  #   ebur128 builtin:    In FL, In FR, Out FL, Out FR, Momentary LUFS, etc.
  #   lufs2gain (ebur128): LUFS, Target LUFS, Gain
  #   linear (builtin):   In, Out, Control, Add, Mult
  filterChainConf = ''
    context.modules = [
      { name = libpipewire-module-filter-chain
        flags = [ nofail ]
        args = {
          node.description = "Advanced Auto Gain"
          media.name       = "Advanced Auto Gain"
          audio.channels   = 2
          audio.position   = [ FL FR ]

          capture.props = {
            node.name   = "effect_input.advanced_auto_gain"
            media.class = Audio/Sink
            audio.channels = 2
            audio.position = [ FL FR ]
          }

          playback.props = {
            node.name   = "effect_output.advanced_auto_gain"
            node.passive = true
            audio.channels = 2
            audio.position = [ FL FR ]
          }

          filter.graph = {
            nodes = [
              #
              # ── Stage 1: Parametric Equalizer (builtin) ────────────
              #
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

              #
              # ── Stage 2: Exciter (Calf LV2) ───────────────────────
              #
              {
                type   = lv2
                name   = exciter
                plugin = "http://calf.sourceforge.net/plugins/Exciter"
                control = {
                  "amount"      = 6.0
                  "drive"       = 8.0
                  "blend"       = 0.0
                  "freq"        = 5500.0
                  "ceil"        = 16000.0
                  "ceil_active" = 0
                  "listen"      = 0
                  "level_in"    = 0.794328
                  "level_out"   = 1.0
                }
              }

              #
              # ── Stage 3: Autogain (EBU R128 measurement + lufs2gain) ──
              #
              # Both ebur128 and lufs2gain live in the ebur128 SPA plugin.
              {
                type  = ebur128
                name  = loudness
                label = ebur128
              }
              {
                type  = ebur128
                name  = gain_calc
                label = lufs2gain
                control = {
                  "Target LUFS" = -12.0
                }
              }
              # Apply computed gain to each channel via builtin linear.
              {
                type  = builtin
                name  = gain_left
                label = linear
                control = { "Add" = 0.0 }
              }
              {
                type  = builtin
                name  = gain_right
                label = linear
                control = { "Add" = 0.0 }
              }

              #
              # ── Stage 4: Limiter (LSP LV2) ────────────────────────
              #
              {
                type   = lv2
                name   = limiter
                plugin = "http://lsp-plug.in/plugins/lv2/limiter_stereo"
                control = {
                  "mode"    = 1
                  "th"      = 1.0
                  "at"      = 5.0
                  "rt"      = 5.0
                  "lk"      = 10.0
                  "boost"   = 1
                  "slink"   = 100.0
                }
              }
            ]

            links = [
              # EQ → Exciter
              { output = "eq_left:Out 1"    input = "exciter:in_l" }
              { output = "eq_right:Out 1"   input = "exciter:in_r" }

              # Exciter → EBU R128 measurement
              { output = "exciter:out_l"    input = "loudness:In FL" }
              { output = "exciter:out_r"    input = "loudness:In FR" }

              # EBU R128 → lufs2gain (control path)
              { output = "loudness:Momentary LUFS"  input = "gain_calc:LUFS" }

              # EBU R128 passthrough → gain application (audio path)
              { output = "loudness:Out FL"  input = "gain_left:In" }
              { output = "loudness:Out FR"  input = "gain_right:In" }

              # lufs2gain → linear multiplier (control path)
              { output = "gain_calc:Gain"   input = "gain_left:Control" }
              { output = "gain_calc:Gain"   input = "gain_right:Control" }

              # Autogain → Limiter
              { output = "gain_left:Out"    input = "limiter:in_l" }
              { output = "gain_right:Out"   input = "limiter:in_r" }
            ]

            inputs  = [ "eq_left:In 1" "eq_right:In 1" ]
            outputs = [ "limiter:out_l" "limiter:out_r" ]
          }
        }
      }
    ]
  '';
in
selfLib.mkModule {
  name = "core.pipewire.pipewireEffects.autogain";

  nixosConfig = {
    assertions = [
      {
        assertion = config.services.pipewire.enable;
        message = "autogain requires services.pipewire.enable = true";
      }
    ];

    # Expose Calf and LSP LV2 plugins to PipeWire's systemd service.
    services.pipewire.extraLv2Packages = with pkgs; [
      calf
      lsp-plugins
    ];

    services.pipewire.configPackages = [
      (pkgs.writeTextDir "share/pipewire/pipewire.conf.d/50-autogain.conf" filterChainConf)
    ];
  };
}
