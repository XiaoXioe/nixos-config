{
  selfLib,
  ...
}:
let
  fifoPath = "/tmp/mpd.fifo";
in
selfLib.mkModule {
  name = "apps.media.music";
  description = "Music player (MPD + rmpc + cava)";

  hmConfig = { config, ... }: {
    programs.cava = {
      enable = true;
      settings = {
        general.framerate = 60;
        input = {
          method = "fifo";
          source = fifoPath;
        };
        color = {
          gradient = 1;
          gradient_color_1 = "'#89b4fa'";
          gradient_color_2 = "'#c4a7e7'";
          gradient_color_3 = "'#ebbcba'";
          gradient_color_4 = "'#f6c177'";
        };
      };
    };

    services.mpd = {
      enable = true;
      musicDirectory = "${config.home.homeDirectory}/Music";
      network = {
        listenAddress = "127.0.0.1";
        startWhenNeeded = true;
        port = 6600;
      };
      extraConfig = ''
        auto_update "yes"
        follow_outside_symlinks "yes"
        follow_inside_symlinks "yes"
        id3v1_encoding "UTF-8"
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
    systemd.user.services.mpd.Unit.RequiresMountsFor = [ "/mnt/data" ];
    programs.rmpc = {
      enable = true;
      config = builtins.readFile ../../../dotfiles/rmpc/config.ron;
    };

    xdg.configFile."rmpc/themes/custom.ron".text = builtins.readFile ../../../dotfiles/rmpc/theme.ron;
  };
}
