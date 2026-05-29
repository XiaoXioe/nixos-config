function ambil
    python3 /mnt/data/file_transfer/receive.py $argv
    # Autocomplete host untuk perintah 'ambil' juga
    complete -c ambil -a "(grep '^Host ' ~/.ssh/config | awk '{print \$2}')"
end
