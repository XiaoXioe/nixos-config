# PipeWire filter-chain audio effects pipeline.
#
# Multi-preset module that translates EasyEffects JSON presets into native
# PipeWire module-filter-chain configurations (SPA-JSON format).  Each preset
# creates a virtual sink that appears as a selectable audio output device.
#
# Supported presets:
#   - "autogain"   →  Parametric EQ → Calf Exciter → EBU R128 Autogain → LSP Limiter
#   - "perfect-eq" →  10-band Parametric EQ (pure builtin, no external plugins)
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.system.core.pipewireEffects;

  # ===========================================================================
  # Helper: render a list of biquad filter attrsets into SPA-JSON array entries.
  # ===========================================================================
  renderFilters =
    indent: filters:
    lib.concatMapStringsSep "\n${indent}" (
      f: "{ type = ${f.type}, freq = ${toString f.freq}, q = ${toString f.q}, gain = ${toString f.gain} }"
    ) filters;

  # ===========================================================================
  # Preset 1: "autogain" — Advanced Auto Gain
  #
  # Source: Advanced Auto Gain.json
  # Chain:  Parametric EQ → Calf Exciter (LV2) → EBU R128 Autogain → LSP Limiter (LV2)
  # ===========================================================================
  autogainEqFilters = [
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

  confAutogain = ''
    context.modules = [
      { name = libpipewire-module-filter-chain
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
                    ${renderFilters "                    " autogainEqFilters}
                  ]
                }
              }
              {
                type  = builtin
                name  = eq_right
                label = param_eq
                config = {
                  filters = [
                    ${renderFilters "                    " autogainEqFilters}
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
                  "level_in"    = 0.794328     # -2.0 dB → 10^(-2/20)
                  "level_out"   = 1.0          #  0.0 dB
                }
              }

              #
              # ── Stage 3: Autogain (native EBU R128 + lufs2gain) ───
              #
              {
                type  = ebur128
                name  = loudness
                label = ebur128
              }
              {
                type  = builtin
                name  = gain_calc
                label = lufs2gain
                control = {
                  "Target LUFS" = -12.0
                }
              }
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
                  "mode"    = 1         # Herm Thin
                  "th"      = 1.0       # threshold 0 dB → linear 1.0
                  "al"      = 5.0       # attack (ms)
                  "rt"      = 5.0       # release (ms)
                  "lk"      = 10.0      # lookahead (ms)
                  "boost"   = 1         # gain-boost on
                  "slink"   = 100.0     # stereo-link 100%
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

  # ===========================================================================
  # Preset 2: "perfect-eq" — Perfect EQ
  #
  # Source: Perfect EQ.json
  # Chain:  10-band Parametric EQ only (pure builtin, zero external plugins)
  # ===========================================================================
  perfectEqFilters = [
    # input-gain = -2.0 dB → preamp via highshelf at 0 Hz
    {
      type = "bq_highshelf";
      freq = 0;
      q = 1.0;
      gain = -2.0;
    }
    # 10 bands (only non-zero gain bands produce audible effect,
    # but all are included for faithful reproduction of the preset)
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
    # output-gain = 0.0 dB → no postamp needed (omitted)
  ];

  confPerfectEq = ''
    context.modules = [
      { name = libpipewire-module-filter-chain
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
              #
              # ── 10-band Parametric Equalizer (builtin) ─────────────
              #
              {
                type  = builtin
                name  = eq_left
                label = param_eq
                config = {
                  filters = [
                    ${renderFilters "                    " perfectEqFilters}
                  ]
                }
              }
              {
                type  = builtin
                name  = eq_right
                label = param_eq
                config = {
                  filters = [
                    ${renderFilters "                    " perfectEqFilters}
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

  # ===========================================================================
  # Preset map: user-facing name → SPA-JSON configuration string.
  # ===========================================================================
  presetMap = {
    "autogain" = confAutogain;
    "perfect-eq" = confPerfectEq;
  };

  # ===========================================================================
  # Per-preset package and LV2 path requirements.
  # Only the "autogain" preset needs external LV2 plugins.
  # ===========================================================================
  presetPackages = {
    "autogain" = with pkgs; [
      calf
      lsp-plugins
    ];
    "perfect-eq" = [ ];
  };

  presetLv2Paths = {
    "autogain" = [
      "${pkgs.calf}/lib/lv2"
      "${pkgs.lsp-plugins}/lib/lv2"
    ];
    "perfect-eq" = [ ];
  };

  selectedPackages = presetPackages.${cfg.preset};
  selectedLv2Paths = presetLv2Paths.${cfg.preset};
in
{
  options.my.system.core.pipewireEffects = {
    enable = lib.mkEnableOption "PipeWire audio effects pipeline";

    preset = lib.mkOption {
      type = lib.types.enum (builtins.attrNames presetMap);
      default = "perfect-eq";
      description = ''
        Select the active audio processing preset.

        - "autogain"   : 30-band EQ → Calf Exciter → EBU R128 Autogain → LSP Limiter
        - "perfect-eq" : 10-band parametric EQ (no external plugins required)
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.services.pipewire.enable;
        message = "pipewireEffects requires services.pipewire.enable = true";
      }
    ];

    # LV2 plugin packages – only installed when the selected preset needs them.
    environment.systemPackages = selectedPackages;

    # Expose LV2 plugin paths to PipeWire's session (only when non-empty).
    environment.variables = lib.mkIf (selectedLv2Paths != [ ]) {
      LV2_PATH = lib.mkDefault (lib.concatStringsSep ":" selectedLv2Paths);
    };

    # Drop-in PipeWire configuration via configPackages.
    services.pipewire.configPackages = [
      (pkgs.writeTextDir "share/pipewire/pipewire.conf.d/50-audio-effects.conf" presetMap.${cfg.preset})
    ];
  };
}
