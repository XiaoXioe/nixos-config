function mpv
    set -l custom_res 0
    set -l mpv_args
    
    # Loop argumen
    set -l skip_next 0
    for i in (seq (count $argv))
        if test $skip_next -eq 1
            set skip_next 0
            continue
        end
        
        if test "$argv[$i]" = "-r"
            set -l next_idx (math $i + 1)
            if test $next_idx -le (count $argv)
                set custom_res $argv[$next_idx]
                set skip_next 1
            else
                echo "Error: -r butuh nilai (contoh: 1080, 480, best)"
                return 1
            end
        else
            set -a mpv_args $argv[$i]
        end
    end
    
    # Logika Eksekusi
    if test "$custom_res" != "0"
        echo "Override Resolusi ke: $custom_res [Prioritas Codec: AVC/H.264]"
        
        if test "$custom_res" = "best"
            # Prioritaskan BEST video dengan codec AVC (H.264) agar GPU GT 610 kuat
            # Jika tidak ada AVC, baru ambil best video apapun (AV1/VP9)
            command mpv --ytdl-format="bestvideo[vcodec^=avc]+bestaudio/bestvideo+bestaudio/best" $mpv_args
        else
            # Prioritaskan Resolusi target dengan codec AVC (H.264)
            # Fallback ke codec lain jika AVC tidak tersedia di resolusi tersebut
            command mpv --ytdl-format="bestvideo[height<=$custom_res][vcodec^=avc]+bestaudio/bestvideo[height<=$custom_res]+bestaudio/best" $mpv_args
            # SKENARIO CERDAS:
            # 1. Coba cari resolusi target (misal 1080) dengan FPS <= 30 dan Codec AVC (Paling Ringan)
            # 2. Jika tidak ada, ambil resolusi target dengan FPS berapapun (misal 60fps) dan Codec AVC
            # 3. Fallback terakhir: ambil apapun yang sesuai resolusi
            # command mpv --ytdl-format="bestvideo[height<=$custom_res][fps<=30][vcodec^=avc]+bestaudio/bestvideo[height<=$custom_res][vcodec^=avc]+bestaudio/best" $mpv_args
        end
    else
        # Default behavior (mengikuti mpv.conf)
        command mpv $mpv_args
    end
end
