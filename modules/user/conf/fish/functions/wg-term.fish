function wg-term
    if test (count $argv) -eq 0
        echo "Penggunaan: wg-term <path-to-config-file>"
        return 1
    end

    set -l conf_file $argv[1]

    if not test -f $conf_file
        echo "Error: File konfigurasi '$conf_file' tidak ditemukan!"
        return 1
    end

    set -l ns_name "vpn_"(random 1000 9999)
    set -l wg_iface "wg_"(random 100 999)
    set -l clean_conf (mktemp)

    echo "--- Menyiapkan Network Namespace: $ns_name ---"

    # --- TAHAP 1: RESOLUSI ENDPOINT ---
    set -l endpoint_line (grep "^Endpoint" $conf_file | head -n 1)
    set -l endpoint_full (echo $endpoint_line | cut -d = -f 2 | string trim)
    set -l endpoint_host (echo $endpoint_full | cut -d : -f 1)
    set -l endpoint_port (echo $endpoint_full | cut -d : -f 2)

    if string match -r "[a-zA-Z]" $endpoint_host
        echo "Resolving Endpoint: $endpoint_host ..."
        set resolved_ip (getent ahosts $endpoint_host | head -n 1 | awk '{print $1}')
        if test -z "$resolved_ip"
            echo "FATAL: Gagal resolve DNS host."
            rm $clean_conf
            return 1
        end
        set final_endpoint "$resolved_ip:$endpoint_port"
    else
        set final_endpoint $endpoint_full
    end

    # --- TAHAP 2: BERSIHKAN CONFIG ---
    cat $conf_file > $clean_conf
    sed -i '/^Address/d' $clean_conf
    sed -i '/^DNS/d' $clean_conf
    sed -i '/^MTU/d' $clean_conf
    sed -i "s|^Endpoint.*|Endpoint = $final_endpoint|" $clean_conf

    set -l wg_addr (grep -P "^Address" $conf_file | head -n 1 | cut -d = -f 2 | string trim)
    if test -z "$wg_addr"
        echo "FATAL: Tidak ada IP Address di config file asli."
        rm $clean_conf
        return 1
    end

    # --- TAHAP 3: SETUP NAMESPACE & DNS (UPDATED) ---
    sudo ip netns add $ns_name
    sudo mkdir -p /etc/netns/$ns_name

    # Cek apakah ada baris DNS di file config
    set -l dns_line (grep "^DNS" $conf_file | head -n 1 | cut -d = -f 2 | string trim)

    if test -n "$dns_line"
        echo "Menggunakan DNS dari Config: $dns_line"
        # Ubah koma menjadi baris baru, lalu tambahkan prefix 'nameserver'
        # Contoh: "9.9.9.9, 1.1.1.1" -> 
        # nameserver 9.9.9.9
        # nameserver 1.1.1.1
        echo $dns_line | tr ',' '\n' | string trim | while read -l ip
            echo "nameserver $ip" | sudo tee -a /etc/netns/$ns_name/resolv.conf > /dev/null
        end
    else
        echo "DNS tidak ditemukan di config. Menggunakan Default (Quad9)."
        echo "nameserver 9.9.9.9" | sudo tee /etc/netns/$ns_name/resolv.conf > /dev/null
    end

    # Setup Interface
    sudo ip link add $wg_iface type wireguard
    sudo ip link set $wg_iface netns $ns_name

    # --- TAHAP 4: AKTIVASI ---
    echo "Set IP: $wg_addr pada interface $wg_iface"
    sudo ip netns exec $ns_name wg setconf $wg_iface $clean_conf
    sudo ip netns exec $ns_name ip link set $wg_iface up
    sudo ip netns exec $ns_name ip addr add $wg_addr dev $wg_iface
    sudo ip netns exec $ns_name ip link set lo up
    sudo ip netns exec $ns_name ip route add default dev $wg_iface

    echo "------------------------------------------------"
    echo "Terminal TERISOLASI. Ketik 'exit' untuk keluar."
    echo "------------------------------------------------"

    # --- TAHAP 5: MASUK SHELL ---
    sudo ip netns exec $ns_name sudo -u $USER fish

    # --- TAHAP 6: CLEANUP ---
    echo "Membersihkan namespace..."
    sudo ip netns del $ns_name
    sudo rm -f /etc/netns/$ns_name/resolv.conf
    sudo rmdir --ignore-fail-on-non-empty /etc/netns/$ns_name 2>/dev/null
    rm $clean_conf
end
