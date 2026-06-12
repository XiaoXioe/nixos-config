{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "scripts.dl-lagu";
  description = "YouTube audio downloader script";

  hmConfig = {
    home.packages = [
      (pkgs.writeShellApplication {
        name = "dl-lagu";
        runtimeInputs = [ pkgs.yt-dlp pkgs.ffmpeg ];
        text = ''
          if [ "$#" -eq 0 ]; then echo "Usage: dl-lagu <url/judul>"; exit 1; fi
          if [[ "$*" =~ ^https?:// ]]; then yt-dlp --no-write-subs -f bestaudio -x --audio-format mp3 --audio-quality 0 --embed-thumbnail --add-metadata "$*"
          else yt-dlp --no-write-subs -f bestaudio -x --audio-format mp3 --audio-quality 0 --embed-thumbnail --add-metadata "ytsearch1:$* audio"; fi
        '';
      })
    ];
  };
}
