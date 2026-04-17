function dl-lagu
    echo "Mencari dan mengunduh: $argv..."
    yt-dlp -x --audio-format mp3 "ytsearch1:$argv audio"
end
