{
  config,
  pkgs,
  pkgsUnstable,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.user.media;
in
{
  options.my.user.media = {
    enable = selfLib.mkBoolOpt false "user media configuration (mpv, yt-dlp, obs)";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      # freetube
      jellyfin-desktop
      gnome-calculator
      stremio-linux-shell
      tesseract
    ];

    programs.gallery-dl = {
      enable = true;
      package = pkgsUnstable.gallery-dl;
      settings = {
        extractor.base-directory = "~/Downloads";
      };
    };

    programs.mpv = {
      enable = true;
      scripts = with pkgs.mpvScripts; [
        uosc
        thumbfast
        autoload
        mpris # Agar bisa dikontrol via media keys OS
        webtorrent-mpv-hook # a hook that allows mpv to stream torrents
        quality-menu # Userscript for MPV that allows you to change youtube video quality (ytdl-format) on the fly
        mpv-playlistmanager # Mpv lua script to create and manage playlists
      ];
      config = {
        # --- Video Output (Universal & Modern) ---
        vo = "gpu";
        gpu-context = "wayland";
        gpu-api = "opengl";

        # --- Hardware Decoding ---
        hwdec = "vaapi-copy";

        # --- UI (Penting untuk uosc) ---
        osc = false;
        osd-bar = false;
        border = false;

        # --- Error Handling (ANTI SPAM) ---
        msg-level = "ffmpeg/video=error,ffmpeg=fatal,audio=error";

        # --- Performance ---
        profile = "fast";
        video-sync = "audio";
        cache = "yes";
        demuxer-max-bytes = "800MiB";
        demuxer-readahead-secs = 120;
        save-position-on-quit = true;
        hr-seek-framedrop = "yes";
        framedrop = "decoder";

        # --- Network & Downloader ---
        network-timeout = 100;
        stream-lavf-o = "reconnect=1,reconnect_streamed=1,reconnect_delay_max=5,reconnect_at_eof=1";

        # --- Format & Quality Rules ---
        ytdl-format = "bestvideo[height<=1080][vcodec^=avc]+bestaudio/best[height<=1080][vcodec^=avc]/bestvideo[height<=720][vcodec^=avc]+bestaudio/best";

        user-agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";

        ytdl-raw-options = "write-auto-subs=,ignore-config=,impersonate=chrome-110:windows-10,retries=infinite,fragment-retries=infinite";
      };

      # Ini adalah padanan dari script-opts
      scriptOpts = {
        ytdl_hook = {
          ytdl_path = "${pkgs.yt-dlp}/bin/yt-dlp";
        };
      };
    };

    programs.yt-dlp = {
      package = pkgs.yt-dlp;
      enable = true;
      settings = {
        # --- Kualitas & Format ---
        format = "'bv+ba/b'";
        merge-output-format = "mkv";

        # --- Metadata ---
        add-metadata = true;
        embed-thumbnail = true;
        embed-subs = true;

        # --- Performance & Anti-Bot ---
        extractor-args = "'generic:impersonate'";
        impersonate = "'chrome-110:windows-10'";
        downloader = "aria2c";
        downloader-args = "aria2c:'-c -x8 -s8 -k1M'";

        # --- Output Filename ---
        output = "'%(title)s [%(id)s].%(ext)s'";
      };
    };

    programs.obs-studio = {
      enable = true;
      plugins = with pkgs.obs-studio-plugins; [
        obs-backgroundremoval
        obs-pipewire-audio-capture
        wlrobs
      ];
    };

    # programs.kitty = {
    #   enable = true;
    #   settings = {
    #     tab_bar_style = "powerline";
    #     tab_powerline_style = "slanted";
    #     shell_integration = "no-sudo";
    #   };
    #   keybindings = {
    #     "ctrl+t" = "new_tab";
    #     "ctrl+w" = "close_tab";
    #     "ctrl+shift+c" = "copy_to_clipboard";
    #     "ctrl+v" = "paste_from_clipboard";
    #     "ctrl+pagedown" = "next_tab";
    #     "ctrl+pageup" = "previous_tab";
    #   };
    # };
  };
}
