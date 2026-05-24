function dl-lagu
    # Gabungkan argumen menjadi satu string
    set -l query "$argv"

    if string match -qr '^https?://' -- "$query"
        # Jika input adalah URL (dimulai dengan http atau https)
        echo "URL terdeteksi, mengunduh langsung: $query"
        yt-dlp --no-write-subs -f bestaudio -x --audio-format mp3 --audio-quality 0 --embed-thumbnail --add-metadata $query
    else
        # Jika input adalah kata kunci pencarian
        echo "Mencari dan mengunduh audio: $query"
        yt-dlp --no-write-subs -f bestaudio -x --audio-format mp3 --audio-quality 0 --embed-thumbnail --add-metadata "ytsearch1:$query audio"
    end
end
