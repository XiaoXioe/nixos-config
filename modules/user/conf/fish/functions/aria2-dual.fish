function aria2-dual -d "Download file menggunakan aria2 dengan eth0 dan wlan0 secara bersamaan"
    # Cek apakah URL dimasukkan
    if test -z "$argv[1]"
        echo "Penggunaan: aria2-dual <URL_FILE>"
        return 1
    end

    set URL $argv[1]

    echo "[-] Mendeteksi IP dan Gateway..."
    
    # Mengambil IP dan Gateway eth0 secara dinamis
    set IP_ETH (ip -4 addr show dev eth0 | awk '/inet / {print $2}' | cut -d/ -f1)
    set GW_ETH (ip route show default dev eth0 | awk '{print $3}')
    
    # Mengambil IP dan Gateway wlan0 secara dinamis
    set IP_WLAN (ip -4 addr show dev wlan0 | awk '/inet / {print $2}' | cut -d/ -f1)
    set GW_WLAN (ip route show default dev wlan0 | awk '{print $3}')

    if test -z "$IP_ETH" -o -z "$IP_WLAN"
        echo "[!] Gagal mendeteksi salah satu antarmuka jaringan. Pastikan eth0 dan wlan0 terhubung."
        return 1
    end

    echo "[v] LAN (eth0)  : IP = $IP_ETH, Gateway = $GW_ETH"
    echo "[v] WiFi (wlan0): IP = $IP_WLAN, Gateway = $GW_WLAN"

    echo "[-] Mempersiapkan Policy-Based Routing (membutuhkan akses sudo)..."
    
    # Hapus aturan lama (jika ada *error/nyangkut* sebelumnya) agar bersih
    sudo ip rule del from $IP_ETH lookup 101 2>/dev/null
    sudo ip rule del from $IP_WLAN lookup 100 2>/dev/null

    # Tambahkan aturan routing baru
    sudo ip route add default via $GW_ETH dev eth0 table 101 2>/dev/null
    sudo ip rule add from $IP_ETH lookup 101
    
    sudo ip route add default via $GW_WLAN dev wlan0 table 100 2>/dev/null
    sudo ip rule add from $IP_WLAN lookup 100

    echo "[-] Memulai unduhan dengan aria2c..."
    # Eksekusi aria2 dengan parameter agresif
    aria2c --disable-ipv6=true \
           --multiple-interface=$IP_ETH,$IP_WLAN \
           -x 16 -s 16 -k 1M \
           "$URL"

    echo "[-] Unduhan selesai atau dihentikan. Membersihkan aturan routing..."
    # Cleanup aturan agar sistem kembali ke kondisi semula
    sudo ip rule del from $IP_ETH lookup 101 2>/dev/null
    sudo ip rule del from $IP_WLAN lookup 100 2>/dev/null
    
    echo "[v] Selesai!"
end
