{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.media.media";
  description = "user media configuration (mpv, yt-dlp, obs)";

  hmConfig = {
    home.packages = with pkgs; [
      gnome-calculator
      ffmpeg
      zbar
    ];
    programs.gallery-dl = {
      enable = true;
      settings = {
        "extractor" = {
          "base-directory" = "~/CloudStorage/Gdrive_Akbar68_Enc/Gallery/";
          "archive" = "~/.local/share/gallery-dl/archive.sqlite3";

          "directory" = [
            "{category}"
            "{user[name]|username|id}"
          ];

          "facebook" = {
            "directory" = [
              "facebook"
              "{username|author|group|group_id|id}"
            ];
          };

          "pixiv" = {
            "ugoira" = "original";
            "postprocessors" = [
              {
                "name" = "ugoira";
                "extension" = "mp4";
                "ffmpeg-location" = "ffmpeg";
              }
              { "name" = "mtime"; }
            ];
          };
        };

        "cookies" = [ "firefox" ];

        "cache" = {
          "file" = "~/.local/share/gallery-dl/cache.sqlite3";
        };
      };
    };

    programs.mpv = {
      enable = true;
      scripts = with pkgs.mpvScripts; [
        uosc
        thumbfast
        autoload
        mpris
        webtorrent-mpv-hook
        quality-menu
        mpv-playlistmanager
      ];
      config = {
        vo = "gpu";
        gpu-context = "wayland";
        gpu-api = "opengl";
        hwdec = "vaapi-copy";
        osc = false;
        osd-bar = false;
        border = false;
        msg-level = "ffmpeg/video=error,ffmpeg=fatal,audio=error";
        profile = "fast";
        video-sync = "audio";
        cache = "yes";
        demuxer-max-bytes = "800MiB";
        demuxer-readahead-secs = 120;
        save-position-on-quit = true;
        hr-seek-framedrop = "yes";
        framedrop = "decoder";
        network-timeout = 100;
        # stream-lavf-o = "reconnect=1,reconnect_streamed=1,reconnect_delay_max=5,reconnect_at_eof=1";
        ytdl-format = "bestvideo[height<=1080][vcodec^=avc]+bestaudio/best[height<=1080][vcodec^=avc]/bestvideo[height<=720][vcodec^=avc]+bestaudio/best";
        ytdl-raw-options = "cookies-from-browser=firefox";
      };
      bindings = {
        RIGHT = "seek 2";
        LEFT = "seek -2";
      };
      scriptOpts = {
        ytdl_hook = {
          ytdl_path = "${pkgs.yt-dlp}/bin/yt-dlp";
        };
      };
    };

    programs.yt-dlp = {
      enable = true;
      settings = {
        format = "'bv+ba/b'";
        merge-output-format = "mkv";
        add-metadata = true;
        embed-thumbnail = true;
        embed-subs = true;
        # extractor-args = "'generic:impersonate'";
        # impersonate = "'Chrome-131:Macos-14'";
        output = "'%(title)s [%(id)s].%(ext)s'";
      };
    };
  };
}
