# Music player stack: MPD (daemon) + rmpc (TUI client) + cava (visualizer).
# Media key support via mpdris2 (MPRIS D-Bus bridge).
#
# Audio flow:
#   MPD → PulseAudio (speakers)
#       → FIFO pipe → cava (bar visualizer)
{
  config,
  lib,
  ...
}:
let
  cfg = config.my.user.music;
  fifoPath = "/tmp/mpd.fifo";
in
{
  options.my.user.music = {
    enable = lib.mkEnableOption "music player (MPD + rmpc + cava)";
  };

  config = lib.mkIf cfg.enable {

    # --- cava: console audio visualizer ---
    # Reads raw audio from the MPD FIFO pipe and renders bar visualizations.
    programs.cava = {
      enable = true;
      settings = {
        general = {
          framerate = 60;
          bars = 0; # 0 = auto-fit bar count to terminal width
        };
        input = {
          method = "fifo";
          source = fifoPath;
        };
        color = {
          gradient = 1;
          gradient_color_1 = "'#89b4fa'"; # Blue  (Catppuccin)
          gradient_color_2 = "'#c4a7e7'"; # Purple (Rosé Pine Iris)
          gradient_color_3 = "'#ebbcba'"; # Pink   (Rosé Pine Rose)
          gradient_color_4 = "'#f6c177'"; # Gold   (Rosé Pine Gold)
        };
      };
    };

    # --- MPD: music player daemon ---
    # Manages the music library, playlists, and playback.
    services.mpd = {
      enable = true;
      musicDirectory = "${config.home.homeDirectory}/Music";

      network.listenAddress = "127.0.0.1";
      network.startWhenNeeded = true; # socket activation
      network.port = 6600;

      extraConfig = ''
        auto_update "yes"
        follow_outside_symlinks "yes"
        follow_inside_symlinks "yes"

        id3v1_encoding "UTF-8"

        # Resume paused on restart instead of auto-playing.
        restore_paused "yes"

        # Output 1: speakers via PulseAudio
        audio_output {
          type            "pulse"
          name            "PulseAudio"
          mixer_type      "software"
        }

        # Output 2: FIFO pipe for cava visualizer
        audio_output {
          type            "fifo"
          name            "Visualizer feed"
          path            "${fifoPath}"
          format          "44100:16:2"
        }
      '';
    };

    systemd.user.services.mpd = {
      Unit = {
        RequiresMountsFor = [ "/mnt/data" ];
      };
    };

    # --- rmpc: TUI client for MPD ---
    programs.rmpc = {
      enable = true;
      config = builtins.readFile ../../conf/rmpc/config.ron;
    };

    xdg.configFile."rmpc/themes/custom.ron".text = builtins.readFile ../../conf/rmpc/theme.ron;
  };
}
