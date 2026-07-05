{
  pkgs,
  selfLib,
  ...
}:

let
  cek_ip = pkgs.writeShellScriptBin "cek_ip" ''
    target_ip="$1"
    if [ -z "$target_ip" ]; then
        echo -e "\033[33m[!] Input kosong. Mengecek IP publik sendiri...\033[0m"
        target_ip=$(${pkgs.curl}/bin/curl -s ipinfo.io/ip)
    fi

    c_head="\033[1;36m"
    c_key="\033[32m"
    c_val="\033[0m"
    c_sep="\033[90m"
    c_warn="\033[1;31m"

    echo
    echo -e "''${c_head}=== 1. Intelligence & Geo Info ===''${c_val}"
    api_url="http://ip-api.com/json/$target_ip?fields=status,message,country,city,isp,org,as,mobile,proxy,hosting,query"
    response=$(${pkgs.curl}/bin/curl -s "$api_url")
    if [ "$(echo "$response" | ${pkgs.jq}/bin/jq -r '.status' 2>/dev/null)" = "fail" ]; then
        echo "❌ Error: $(echo "$response" | ${pkgs.jq}/bin/jq -r '.message' 2>/dev/null)"
    else
        echo "$response" | ${pkgs.jq}/bin/jq -r 'to_entries | .[] | "\(.key) \(.value)"' | while read -r key value; do
            case "$key" in
                query) key="Target IP" ;;
                status) continue ;;
                country) key="Country" ;;
                city) key="City" ;;
                isp) key="ISP Name" ;;
                org) key="Organization" ;;
                as) key="AS Number" ;;
                mobile)
                    key="Mobile Data"
                    if [ "$value" = "true" ]; then value="\033[35mYES\033[0m"; else value="No"; fi
                    ;;
                proxy)
                    key="Proxy/VPN"
                    if [ "$value" = "true" ]; then value="''${c_warn}DETECTED''${c_val}"; else value="No"; fi
                    ;;
                hosting)
                    key="Data Center"
                    if [ "$value" = "true" ]; then value="\033[33mYES (Server/VPS)\033[0m"; else value="No"; fi
                    ;;
            esac
            printf "''${c_key}%-15s''${c_val} ''${c_sep}:''${c_val} %b\n" "$key" "$value"
        done
    fi

    echo
    echo -e "''${c_head}=== 2. Registration (Whois) ===''${c_val}"
    filters="netname|descr|role|person|address|country|inetnum|CIDR"
    ${pkgs.whois}/bin/whois "$target_ip" 2>/dev/null \
        | grep -Ei "$filters" \
        | awk '!seen[$0]++' \
        | awk -F: -v c_key="$c_key" -v c_val="$c_val" -v c_sep="$c_sep" '
            {
                key = $1; $1 = ""; val = substr($0, 2);
                gsub(/^[ \t]+|[ \t]+$/, "", key); gsub(/^[ \t]+|[ \t]+$/, "", val);
                if (val != "") printf "%s%-15s%s %s: %s%s%s\n", c_key, key, c_val, c_sep, c_val, val, c_val
            }
        ' | head -n 10

    my_ip=$(${pkgs.curl}/bin/curl -s ipinfo.io/ip)
    if [ "$target_ip" != "$my_ip" ]; then
        echo
        echo -e "''${c_head}=== 3. Quick Port Scan (Top 100) ===''${c_val}"
        echo -e "\033[90mScanning... (Ctrl+C to skip)\033[0m"
        ${pkgs.nmap}/bin/nmap -F -T4 --open -Pn "$target_ip" 2>/dev/null | grep -E "^[0-9]+/tcp" | awk -v c_val="$c_val" '
            { printf "  -> Port %-5s : %s%s\n", $1, c_val, $3 }
        '
        if [ ''${PIPESTATUS[0]} -ne 0 ]; then
            echo "  (No open ports found on Top 100 or Host Firewall active)"
        fi
    else
        echo
        echo -e "\033[90m[Skip Scan: Target adalah IP sendiri]\033[0m"
    fi
    echo
  '';

  wayres = pkgs.writeShellScriptBin "wayres" ''
    if [ $# -eq 0 ]; then
        echo "❌ Gunakan: wayres [portrait|p], atau [auto|reset]"
        exit 1
    fi

    case "$1" in
        p|portrait)
            echo "📱 Mengubah ke Mode PORTRAIT..."
            waydroid prop set persist.waydroid.width 540
            waydroid prop set persist.waydroid.height 1010
            waydroid prop set persist.waydroid.density 240
            ;;
        a|auto|reset)
            echo "🔄 Mengembalikan ke Mode DEFAULT (Auto-Detect)..."
            waydroid prop set persist.waydroid.width ""
            waydroid prop set persist.waydroid.height ""
            waydroid prop set persist.waydroid.density ""
            ;;
        *)
            echo "❌ Opsi tidak dikenal. Gunakan 'p', 'l', atau 'a' (auto)."
            exit 1
            ;;
    esac

    echo "🔄 Merestart sesi Waydroid..."
    waydroid session stop
    echo "✅ Selesai! Silakan jalankan Waydroid kembali."
  '';

  softsub = pkgs.writeShellScriptBin "softsub" ''
    if [ $# -lt 2 ]; then
        echo "❌ Error: Argumen kurang."
        echo "💡 Cara pakai: softsub <video_sumber> <subtitle.srt> [video_hasil]"
        exit 1
    fi

    video="$1"
    srt="$2"
    output="''${3:-output_softsub.mkv}"

    echo "🎬 Memulai proses softsub ke $output..."

    if [[ "$output" =~ \.[Mm][Pp]4$ ]]; then
        ${pkgs.ffmpeg}/bin/ffmpeg -hide_banner -loglevel error -stats -i "$video" -i "$srt" -c:v copy -c:a copy -c:s mov_text "$output"
    else
        ${pkgs.ffmpeg}/bin/ffmpeg -hide_banner -loglevel error -stats -i "$video" -i "$srt" -c copy "$output"
    fi

    ffmpeg_status=$?
    echo ""

    if [ $ffmpeg_status -eq 0 ]; then
        echo "✅ Selesai! File disimpan sebagai: $output"
    else
        echo "❌ Gagal memproses video. Pastikan file tidak rusak atau coba output ke .mkv."
        rm -f "$output"
        exit 1
    fi
  '';

  mpv-wrapper = pkgs.writeShellScriptBin "mpv" ''
    custom_res=0
    mpv_args=()
    skip_next=0
    args=("$@")
    for ((i=0; i<''${#args[@]}; i++)); do
        if [ $skip_next -eq 1 ]; then
            skip_next=0
            continue
        fi
        if [ "''${args[i]}" = "-r" ]; then
            next_idx=$((i + 1))
            if [ $next_idx -lt ''${#args[@]} ]; then
                custom_res="''${args[next_idx]}"
                skip_next=1
            else
                echo "Error: -r butuh nilai (contoh: 1080, 480, best)"
                exit 1
            fi
        else
            mpv_args+=("''${args[i]}")
        fi
    done

    if [ "$custom_res" != "0" ]; then
        echo "Override Resolusi ke: $custom_res [Prioritas Codec: AVC/H.264]"
        if [ "$custom_res" = "best" ]; then
            exec ${pkgs.mpv}/bin/mpv --ytdl-format="bestvideo[vcodec^=avc]+bestaudio/bestvideo+bestaudio/best" "''${mpv_args[@]}"
        else
            exec ${pkgs.mpv}/bin/mpv --ytdl-format="bestvideo[height<=$custom_res][vcodec^=avc]+bestaudio/bestvideo[height<=$custom_res]+bestaudio/best" "''${mpv_args[@]}"
        fi
    else
        exec ${pkgs.mpv}/bin/mpv "''${mpv_args[@]}"
    fi
  '';
in
selfLib.mkModule {
  name = "scripts.custom-functions";
  description = "Migrated custom bash scripts (cek_ip, wayres, softsub, mpv-wrapper)";

  hmConfig = hmOpts: {
    home.packages = [
      cek_ip
      wayres
      softsub
      mpv-wrapper
    ];
  };
}
