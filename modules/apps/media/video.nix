{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.media.video";
  description = "Video and image media players, downloaders, and utilities";

  flatpakCfg = {
    "org.gnome.gThumb" = {
      enable = true;
      flatpak = false;
      nativePkgs = pkgs.gthumb;
    };
  };

  hmConfig = hmOpts: {
    home.packages = with pkgs; [
      ffmpeg
      zbar
    ];

    programs.gallery-dl = {
      enable = true;
      settings = {
        "extractor" = {
          "base-directory" = "~/CloudStorage/gdrive-akbar-68-decrypted/Gallery/";
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

        "cookies" = [
          "zen"
          "${hmOpts.config.home.homeDirectory}/.config/zen/${hmOpts.config.home.username}"
        ];

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
        alang = "id,ind,en,eng";
        ytdl-format = "bestvideo[height<=1080][vcodec^=avc]+(bestaudio[language=id]/bestaudio[language=ind]/bestaudio)/best[height<=1080][vcodec^=avc]/bestvideo[height<=720][vcodec^=avc]+bestaudio/best";
        ytdl-raw-options = "cookies-from-browser=firefox,audio-multistreams=";
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
        output = "'%(title)s [%(id)s].%(ext)s'";

        cookies-from-browser = "firefox";

        embed-metadata = true;
        embed-thumbnail = true;
        embed-chapters = true;

        embed-subs = true;
        sub-langs = "en,id,-live_chat";

        concurrent-fragments = 4;
        no-mtime = true;
        sponsorblock-mark = "all";
        sponsorblock-remove = "sponsor";
      };
    };
  };
}
