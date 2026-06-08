function softsub -d "Bungkus video dan SRT jadi softsub instan tanpa render ulang"
    # Cek apakah jumlah argumen sesuai
    if test (count $argv) -lt 2
        echo "❌ Error: Argumen kurang."
        echo "💡 Cara pakai: softsub <video_sumber> <subtitle.srt> [video_hasil]"
        return 1
    end

    set video $argv[1]
    set srt $argv[2]

    if test (count $argv) -eq 3
        set output $argv[3]
    else
        set output "output_softsub.mkv"
    end

    set cmd nix run nixpkgs#ffmpeg --

    echo "🎬 Memulai proses softsub ke $output..."

    if string match -qi "*.mp4" "$output"
        $cmd -hide_banner -loglevel error -stats -i "$video" -i "$srt" -c:v copy -c:a copy -c:s mov_text "$output"
    else
        $cmd -hide_banner -loglevel error -stats -i "$video" -i "$srt" -c copy "$output"
    end

    # SIMPAN STATUS FFMPEG SEBELUM TERTILAP PERINTAH LAIN
    set ffmpeg_status $status

    # Memberikan baris baru
    echo ""

    # Cek menggunakan variabel yang sudah disimpan
    if test $ffmpeg_status -eq 0
        echo "✅ Selesai! File disimpan sebagai: $output"
    else
        echo "❌ Gagal memproses video. Pastikan file tidak rusak atau coba output ke .mkv."
        # Opsional: hapus file output yang korup
        rm -f "$output" 
        return 1
    end
end
