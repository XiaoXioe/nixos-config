function kirim
    # Ganti path di bawah ini sesuai lokasi Anda menyimpan send.py tadi
    python3 /mnt/data/file_transfer/send.py $argv
    # Autocomplete untuk host SSH (Opsional, agar bisa tekan Tab setelah ketik 'ke')
    # Ini akan membaca host dari ~/.ssh/config Anda
    complete -c kirim -a "(grep '^Host ' ~/.ssh/config | awk '{print \$2}')"
end
