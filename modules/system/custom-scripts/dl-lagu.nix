{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.my.custompkgs.dl-lagu;

  dl-lagu-pkg = pkgs.writeShellApplication {
    name = "dl-lagu";

    runtimeInputs = [
      pkgs.yt-dlp
      pkgs.ffmpeg
    ];

    text = ''
      if [ "$#" -eq 0 ]; then
        echo "Error: Masukkan URL atau judul lagu."
        echo "Penggunaan: dl-lagu <url atau judul lagu>"
        exit 1
      fi

      query="$*"

      # Regex Bash untuk mengecek apakah input dimulai dengan http:// atau https://
      if [[ "$query" =~ ^https?:// ]]; then
        echo "URL terdeteksi, mengunduh langsung: $query"
        yt-dlp --no-write-subs -f bestaudio -x --audio-format mp3 --audio-quality 0 --embed-thumbnail --add-metadata "$query"
      else
        echo "Mencari dan mengunduh audio: $query"
        yt-dlp --no-write-subs -f bestaudio -x --audio-format mp3 --audio-quality 0 --embed-thumbnail --add-metadata "ytsearch1:$query audio"
      fi
    '';
  };
in
{
  options.my.custompkgs.dl-lagu = {
    enable = lib.mkEnableOption "YouTube audio downloader script";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      dl-lagu-pkg
    ];
  };
}
