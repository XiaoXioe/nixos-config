{
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.media.dl-lagu";
  description = "YouTube audio downloader script";

  hmConfig =
    { config, pkgs, ... }:
    let
      ytdlpPkg = config.programs.yt-dlp.package;
      dlLaguApp =
        selfLib.mkApp pkgs "dl-lagu"
          ''
            if [ "$#" -eq 0 ]; then
              echo "Error: Masukkan URL atau judul lagu."
              echo "Penggunaan: dl-lagu <url atau judul lagu>"
              exit 1
            fi

            query="$*"

            if [[ "$query" =~ ^https?:// ]]; then
              echo "URL terdeteksi, mengunduh langsung: $query"
              ${ytdlpPkg}/bin/yt-dlp --no-write-subs -f bestaudio -x --audio-format mp3 --audio-quality 0 --embed-thumbnail --add-metadata "$query"
            else
              echo "Mencari dan mengunduh audio: $query"
              ${ytdlpPkg}/bin/yt-dlp --no-write-subs -f bestaudio -x --audio-format mp3 --audio-quality 0 --embed-thumbnail --add-metadata "ytsearch1:$query audio"
            fi
          ''
          [
            ytdlpPkg
            pkgs.ffmpeg
          ];
    in
    {
      home.packages = [ dlLaguApp ];
    };
}
