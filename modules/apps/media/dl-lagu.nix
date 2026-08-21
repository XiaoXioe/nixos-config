{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:

let
  useDistrobox = config.my.apps.media.dl-lagu.distrobox.enable;

  ytdlpRunner =
    if useDistrobox then
      "${pkgs.distrobox}/bin/distrobox enter arch -- yt-dlp"
    else
      "${pkgs.yt-dlp}/bin/yt-dlp";

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
          ${ytdlpRunner} --no-write-subs -f bestaudio -x --audio-format mp3 --audio-quality 0 --embed-thumbnail --add-metadata "$query"
        else
          echo "Mencari dan mengunduh audio: $query"
          ${ytdlpRunner} --no-write-subs -f bestaudio -x --audio-format mp3 --audio-quality 0 --embed-thumbnail --add-metadata "ytsearch1:$query audio"
        fi
      ''
      (
        lib.optionals (!useDistrobox) [
          pkgs.yt-dlp
          pkgs.ffmpeg
        ]
      );
in
selfLib.mkModule {
  name = "apps.media.dl-lagu";
  description = "YouTube audio downloader script with Arch Distrobox backend support";

  distroboxCfg = selfLib.distrobox.arch {
    # image, distro — auto dari helper
    packages = [
      "yt-dlp"
      "ffmpeg"
      "atomicparsley"
      "python-mutagen"
    ];
    generateHostWrapper = false;
  };

  hmConfig = {
    home.packages = [ dlLaguApp ];
  };
}
