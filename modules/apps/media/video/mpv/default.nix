{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.media.video.mpv";
  description = "MPV media player configuration with GPU hardware acceleration, uosc UI, and YouTube dubbing support";

  hmConfig = hmOpts: {
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
  };
}
