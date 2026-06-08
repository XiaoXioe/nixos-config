function wayres --description "Ganti resolusi Waydroid (Portrait/Landscape/Auto)"
    # Cek argumen
    if test (count $argv) -eq 0
        echo "❌ Gunakan: wayres [portrait|p], atau [auto|reset]"
        return 1
    end

    switch $argv[1]
        case p portrait
            echo "📱 Mengubah ke Mode PORTRAIT..."
            waydroid prop set persist.waydroid.width 540
            waydroid prop set persist.waydroid.height 1010
            waydroid prop set persist.waydroid.density 240

        case a auto reset
            echo "🔄 Mengembalikan ke Mode DEFAULT (Auto-Detect)..."
            # Menghapus nilai custom agar kembali ke pengaturan bawaan
            waydroid prop set persist.waydroid.width ""
            waydroid prop set persist.waydroid.height ""
            # Density juga dikembalikan ke default (biasanya otomatis mengikuti host)
            waydroid prop set persist.waydroid.density ""

        case '*'
            echo "❌ Opsi tidak dikenal. Gunakan 'p', 'l', atau 'a' (auto)."
            return 1
    end

    echo "🔄 Merestart sesi Waydroid..."
    waydroid session stop
    echo "✅ Selesai! Silakan jalankan Waydroid kembali."
end
