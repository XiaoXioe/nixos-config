function cek-cache --description 'Cek asal cache dari sebuah paket Nix'
    # Gunakan command -v yang lebih aman dari which
    set bin_path (command -v $argv[1])
    
    if test -z "$bin_path"
        echo "Error: Perintah '$argv[1]' tidak ditemukan."
        return 1
    end
    
    # Cari path asli melewati semua symlink
    set real_path (readlink -f $bin_path)
    
    # Pastikan path memang berada di dalam /nix/store
    if not string match -q -r '^/nix/store/' $real_path
        echo "Error: Path bukan berasal dari Nix store ($real_path)"
        return 1
    end
    
    # Ekstrak path utama (contoh: /nix/store/hash-nama-versi)
    set store_path (string match -r '^/nix/store/[^/]+' $real_path)
    
    # Validasi terakhir sebelum menjalankan nix path-info
    if test -z "$store_path"
        echo "Error: Gagal memproses path Nix store."
        return 1
    end
    
    echo "Mengecek signatures untuk: $store_path"
    nix path-info --sigs $store_path
end
