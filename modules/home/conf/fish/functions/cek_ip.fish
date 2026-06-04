function cek_ip
    set -l target_ip $argv[1]
    
    # 1. Validasi Input
    if test -z "$target_ip"
        echo (set_color yellow)"[!] Input kosong. Mengecek IP publik sendiri..."(set_color normal)
        set target_ip (curl -s ipinfo.io/ip)
    end
    
    # Definisi Warna
    set -l c_head (set_color -o cyan)
    set -l c_key (set_color green)
    set -l c_val (set_color normal)
    set -l c_sep (set_color brblack)
    set -l c_warn (set_color -o red)
    
    # --- SECTION 1: INTELLIGENCE (Geo + Type) ---
    echo
    echo "$c_head=== 1. Intelligence & Geo Info ===$c_val"
    
    # Kita menggunakan ip-api.com karena menyediakan field 'mobile', 'proxy', dan 'hosting' gratis
    set -l api_url "http://ip-api.com/json/$target_ip?fields=status,message,country,city,isp,org,as,mobile,proxy,hosting,query"
    
    curl -s "$api_url" | jq -r 'to_entries | .[] | "\(.key) \(.value)"' | while read -l key value
        switch $key
            case query; set key "Target IP"
            case status; continue
            case country; set key "Country"
            case city; set key "City"
            case isp; set key "ISP Name"
            case org; set key "Organization"
            case as; set key "AS Number"
                
                # Highlight khusus untuk Tipe IP
            case mobile
                set key "Mobile Data"
                if test "$value" = "true"; set value (set_color magenta)"YES"$c_val; else; set value "No"; end
            case proxy
                set key "Proxy/VPN"
                if test "$value" = "true"; set value $c_warn"DETECTED"$c_val; else; set value "No"; end
            case hosting
                set key "Data Center"
                if test "$value" = "true"; set value (set_color yellow)"YES (Server/VPS)"$c_val; else; set value "No"; end
        end
        
        printf "%s%-15s%s %s: %s%s%s\n" $c_key $key $c_val $c_sep $c_val $value $c_val
    end
    
    # --- SECTION 2: REGISTRATION (Whois) ---
    echo
    echo "$c_head=== 2. Registration (Whois) ===$c_val"
    set -l filters "netname|descr|role|person|address|country|inetnum|CIDR"
    
    whois "$target_ip" \
            | grep -Ei "$filters" \
            | awk '!seen[$0]++' \
            | awk -F: -v c_key=$c_key -v c_val=$c_val -v c_sep=$c_sep '
        {
            key = $1; $1 = ""; val = substr($0, 2);
            gsub(/^[ \t]+|[ \t]+$/, "", key); gsub(/^[ \t]+|[ \t]+$/, "", val);
            if (val != "") printf "%s%-15s%s %s: %s%s%s\n", c_key, key, c_val, c_sep, c_val, val, c_val
        }
    ' | head -n 10 # Batasi 10 baris agar tidak flooding
    
    # --- SECTION 3: RECONNAISSANCE (Nmap) ---
    # Hanya dijalankan jika bukan IP sendiri (untuk efisiensi waktu)
    set -l my_ip (curl -s ipinfo.io/ip)
    
    if test "$target_ip" != "$my_ip"
        echo
        echo "$c_head=== 3. Quick Port Scan (Top 100) ===$c_val"
        echo (set_color brblack)"Scanning... (Ctrl+C to skip)"(set_color normal)
        
        # -F: Fast mode (100 port terpopuler)
        # -T4: Timing aggressive (lebih cepat)
        # --open: Hanya tampilkan port terbuka
        # -Pn: Treat host as online (skip ping blocking)
        nmap -F -T4 --open -Pn "$target_ip" | grep -E "^[0-9]+/tcp" | awk -v c_val=$c_val '
            { printf "  -> Port %-5s : %s%s\n", $1, c_val, $3 }
        '
        
        # Jika hasil kosong (grep gagal), nmap mungkin tidak menemukan port terbuka
        if test $status -ne 0
            echo "  (No open ports found on Top 100 or Host Firewall active)"
        end
    else
        echo
        echo (set_color brblack)"[Skip Scan: Target adalah IP sendiri]"(set_color normal)
    end
    echo
end
