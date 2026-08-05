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
        autofit-larger = "90%x90%";
        msg-level = "ffmpeg/video=error,ffmpeg=fatal,audio=error";
        profile = "fast";
        video-sync = "audio";
        cache = "yes";
        demuxer-max-bytes = "800MiB";
        demuxer-readahead-secs = 120;
        save-position-on-quit = true;
        hr-seek-framedrop = "yes";
        framedrop = "decoder";
        network-timeout = 10;
        alang = "id,ind,en,eng";
        osd-font = "sans-serif";
        sub-font = "sans-serif";
        ytdl-format = "bestvideo[height<=?1080][vcodec^=avc]+(bestaudio[language=id]/bestaudio[language=ind]/bestaudio)/bestvideo[height<=?1080][vcodec^=vp9]+(bestaudio[language=id]/bestaudio[language=ind]/bestaudio)/best[height<=?1080]/best";
        ytdl-raw-options = "audio-multistreams=,force-ipv4=,extractor-args=youtube:player_client=mweb+web";
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
