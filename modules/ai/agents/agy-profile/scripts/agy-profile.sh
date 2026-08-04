#!/usr/bin/env bash
set -euo pipefail

REAL_HOME="$HOME"
AGY_DIR="$REAL_HOME/.gemini/antigravity-cli"
CRED_DIR_BASE="$AGY_DIR/credentials"
CACHE_DIR="/tmp/agy-profile-cache-$USER"
mkdir -p "$CACHE_DIR"

is_profile_active() {
    local pname="$1"
    [ -z "$pname" ] && return 1
    local cred_dir="$CRED_DIR_BASE/$pname"
    pgrep -f "bwrap.*$cred_dir/" >/dev/null 2>&1
}

get_profile_email() {
    local pname="$1"
    local cred_file="$CRED_DIR_BASE/$pname/antigravity-oauth-token"
    if [ -f "$cred_file" ]; then
        jq -r '.id_token // empty' "$cred_file" 2>/dev/null \
            | cut -d. -f2 2>/dev/null \
            | base64 -d 2>/dev/null \
            | jq -r '.email // "Unknown Email"' 2>/dev/null || echo "Unknown Email"
    else
        echo "Token Not Found"
    fi
}

fetch_profile_quota() {
    local pname="$1"
    local cred_dir="$CRED_DIR_BASE/$pname"
    local cred_file="$cred_dir/antigravity-oauth-token"
    local cache_file="$CACHE_DIR/$pname.json"

    if [ ! -f "$cred_file" ]; then
        echo '{"error": "No token file"}'
        return 1
    fi

    if [ -f "$cache_file" ]; then
        local mtime
        mtime=$(stat -c %Y "$cache_file" 2>/dev/null || echo 0)
        local now
        now=$(date +%s)
        if [ $((now - mtime)) -lt 60 ]; then
            cat "$cache_file"
            return 0
        fi
    fi

    local token
    token=$(jq -r '.token.access_token // empty' "$cred_file" 2>/dev/null)
    local res=""

    if [ -n "$token" ]; then
        res=$(curl -s -m 4 -X POST \
            -H "Authorization: Bearer $token" \
            -H "Content-Type: application/json" \
            -H "User-Agent: AntigravityCLI/1.0" \
            -d '{}' \
            "https://cloudcode-pa.googleapis.com/v1internal:retrieveUserQuotaSummary" 2>/dev/null)
    fi

    # Jika token expired (tidak mengembalikan .groups), jalankan headless agy untuk auto-refresh token
    if ! echo "$res" | jq -e '.groups' >/dev/null 2>&1; then
        bwrap \
            --dev-bind / / \
            --bind "$cred_dir/antigravity-oauth-token" "$AGY_DIR/antigravity-oauth-token" \
            --bind "$cred_dir/installation_id" "$AGY_DIR/installation_id" \
            --bind "$cred_dir/jetski_state.pbtxt" "$AGY_DIR/jetski_state.pbtxt" \
            --setenv DBUS_SESSION_BUS_ADDRESS unix:path=/dev/null \
            agy models >/dev/null 2>&1

        token=$(jq -r '.token.access_token // empty' "$cred_file" 2>/dev/null)
        if [ -n "$token" ]; then
            res=$(curl -s -m 4 -X POST \
                -H "Authorization: Bearer $token" \
                -H "Content-Type: application/json" \
                -H "User-Agent: AntigravityCLI/1.0" \
                -d '{}' \
                "https://cloudcode-pa.googleapis.com/v1internal:retrieveUserQuotaSummary" 2>/dev/null)
        fi
    fi

    if echo "$res" | jq -e '.groups' >/dev/null 2>&1; then
        echo "$res" > "$cache_file"
        echo "$res"
    else
        echo '{"error": "Expired or invalid token"}'
        return 1
    fi
}

show_profile_preview() {
    local raw_pname="$1"
    local pname="${raw_pname%% (*}"
    pname="${pname%% *}"

    if [ -z "$pname" ]; then
        echo "Pilih profile untuk melihat preview status dan kuota model."
        return
    fi

    local email
    email=$(get_profile_email "$pname")

    local status_icon="⚪ Inactive"
    if is_profile_active "$pname"; then
        status_icon="🟢 ACTIVE"
    fi

    echo "👤 Profile: $pname | 📧 $email | $status_icon"
    echo "──────────────────────────────────────────────────────────────────"

    local quota_json
    quota_json=$(fetch_profile_quota "$pname" 2>/dev/null || true)

    if echo "$quota_json" | jq -e '.groups' >/dev/null 2>&1; then
        echo "📊 MODEL QUOTA & LIMITS:"
        echo "$quota_json" | jq -r '
            def fmt_time:
                if . == null then ""
                else
                    (fromdateiso8601 - now) as $diff |
                    if $diff <= 0 then "Ready"
                    else
                        ($diff / 86400 | floor) as $d |
                        (($diff % 86400) / 3600 | floor) as $h |
                        (($diff % 3600) / 60 | floor) as $m |
                        if $d > 0 then "\($d)d \($h)h"
                        elif $h > 0 then "\($h)h \($m)m"
                        else "\($m)m"
                        end
                    end
                end;

            .groups[]? | 
            "  🔹 " + .displayName + ":\n" + 
            (.buckets | map(
                "     • " + .displayName + ": " + 
                ((.remainingFraction * 100 | round | tostring) + "% sisa") + 
                (if .resetTime then " (Reset: dlm " + (.resetTime | fmt_time) + ")" else "" end)
            ) | join("\n"))
        '
    else
        echo "⚠️ STATUS QUOTA:"
        echo "  🔴 Token Expired atau Login Diperlukan."
        echo "  Jalankan profil 'agy-profile $pname' untuk login ulang."
    fi
}

show_all_usage() {
    echo "📊 MENAMPILKAN USAGE & KUOTA MODEL UNTUK SEMUA AKUN:"
    echo ""
    if [ -d "$CRED_DIR_BASE" ]; then
        for d in "$CRED_DIR_BASE"/*/; do
            if [ -d "$d" ]; then
                local pname
                pname="$(basename "$d")"
                if [ "$pname" != "*" ]; then
                    show_profile_preview "$pname"
                    echo ""
                    echo "--------------------------------------------------"
                    echo ""
                fi
            fi
        done
    else
        echo "Belum ada profile terdaftar."
    fi
}

list_profiles() {
    if [ -d "$CRED_DIR_BASE" ]; then
        echo "Daftar akun/profile yang tersedia:"
        found=0
        for d in "$CRED_DIR_BASE"/*/; do
            if [ -d "$d" ]; then
                pname="$(basename "$d")"
                if [ "$pname" != "*" ]; then
                    email=$(get_profile_email "$pname")
                    if is_profile_active "$pname"; then
                        echo "  - $pname ($email) [🟢 ACTIVE]"
                    else
                        echo "  - $pname ($email)"
                    fi
                    found=1
                fi
            fi
        done
        if [ "$found" -eq 0 ]; then
            echo "  (Belum ada profile yang terdaftar)"
        fi
    else
        echo "Belum ada akun/profile yang terdaftar."
    fi
}

launch_profile() {
    local profile_name="$1"
    shift 1
    local cred_dir="$CRED_DIR_BASE/$profile_name"

    if is_profile_active "$profile_name"; then
        echo "ℹ️  Catatan: Profile '$profile_name' sedang aktif di sesi terminal lain."
    fi

    if [ ! -d "$cred_dir" ]; then
        echo "Profile '$profile_name' belum ada. Membuat direktori credentials..."
        mkdir -p "$cred_dir"
        echo "Jalankan login pertama di agy untuk menyimpan token."
    fi

    for f in antigravity-oauth-token installation_id jetski_state.pbtxt; do
        [ ! -f "$cred_dir/$f" ] && touch "$cred_dir/$f"
    done

    echo "Menjalankan agy untuk profile: $profile_name (namespace mode)"
    exec bwrap \
        --dev-bind / / \
        --bind "$cred_dir/antigravity-oauth-token" "$AGY_DIR/antigravity-oauth-token" \
        --bind "$cred_dir/installation_id" "$AGY_DIR/installation_id" \
        --bind "$cred_dir/jetski_state.pbtxt" "$AGY_DIR/jetski_state.pbtxt" \
        --setenv DBUS_SESSION_BUS_ADDRESS unix:path=/dev/null \
        --die-with-parent \
        agy "$@"
}

relogin_profile() {
    local profile_name="$1"
    shift 1
    local cred_dir="$CRED_DIR_BASE/$profile_name"

    if is_profile_active "$profile_name"; then
        echo "⚠️  PERINGATAN: Profile '$profile_name' sedang AKTIF dijalankan di sesi terminal lain!"
        echo -n "Apakah Anda yakin ingin mereset token profile yang sedang aktif ini? [y/N]: "
        read -r confirm
        case "$confirm" in
            [yY][eE][sS]|[yY])
                ;;
            *)
                echo "Reset token profile '$profile_name' dibatalkan."
                return 1
                ;;
        esac
    fi

    echo "Mereset token login untuk profile '$profile_name'..."
    mkdir -p "$cred_dir"
    rm -f "$cred_dir/antigravity-oauth-token" "$cred_dir/installation_id" "$cred_dir/jetski_state.pbtxt"
    rm -f "$CACHE_DIR/$profile_name.json"
    touch "$cred_dir/antigravity-oauth-token" "$cred_dir/installation_id" "$cred_dir/jetski_state.pbtxt"
    launch_profile "$profile_name" "$@"
}

delete_profile() {
    local profile_name="$1"
    local cred_dir="$CRED_DIR_BASE/$profile_name"
    if [ ! -d "$cred_dir" ]; then
        echo "Profile '$profile_name' tidak ditemukan."
        return 1
    fi

    if is_profile_active "$profile_name"; then
        echo "⚠️  PERINGATAN: Profile '$profile_name' sedang AKTIF dijalankan di sesi terminal lain!"
        echo -n "Apakah Anda yakin ingin menghapus profile yang sedang aktif ini? [y/N]: "
        read -r confirm
        case "$confirm" in
            [yY][eE][sS]|[yY])
                ;;
            *)
                echo "Penghapusan profile '$profile_name' dibatalkan."
                return 1
                ;;
        esac
    fi

    rm -rf "$cred_dir"
    rm -f "$CACHE_DIR/$profile_name.json"
    echo "Profile '$profile_name' telah berhasil dihapus."
}

select_profile_fzf() {
    local label="$1"
    local formatted_profiles=()
    for p in "${profiles[@]}"; do
        local email
        email=$(get_profile_email "$p")
        if is_profile_active "$p"; then
            formatted_profiles+=("$p ($email) [🟢 Aktif]")
        else
            formatted_profiles+=("$p ($email) [⚪ Tidak Aktif]")
        fi
    done

    local choice
    choice=$(printf '%s\n' "${formatted_profiles[@]}" | fzf \
        --height=95% \
        --min-height=20 \
        --layout=reverse \
        --border=rounded \
        --border-label=" $label " \
        --prompt="  Profile ❯ " \
        --pointer="❯" \
        --preview="agy-profile preview {}" \
        --preview-window=right:55%:wrap) || return 1

    echo "${choice%% (*}"
}

show_help() {
    echo "Antigravity Profile Manager (agy-profile)"
    echo ""
    echo "Penggunaan:"
    echo "  agy-profile                     Buka menu interaktif dengan preview kuota model"
    echo "  agy-profile <nama_profile>       Jalankan agy dengan profile tersebut"
    echo "  agy-profile -u, --usage, usage   Tampilkan penggunaan/kuota model semua akun"
    echo "  agy-profile -l, --list, list    Tampilkan daftar profile & email"
    echo "  agy-profile add <nama_profile>  Tambah profile baru & jalankan"
    echo "  agy-profile rm <nama_profile>   Hapus profile"
    echo "  agy-profile -h, --help, help    Tampilkan bantuan ini"
}

interactive_menu() {
    while true; do
        profiles=()
        active_profiles=()
        if [ -d "$CRED_DIR_BASE" ]; then
            for d in "$CRED_DIR_BASE"/*/; do
                if [ -d "$d" ]; then
                    pname="$(basename "$d")"
                    if [ "$pname" != "*" ]; then
                        profiles+=("$pname")
                        if is_profile_active "$pname"; then
                            active_profiles+=("$pname")
                        fi
                    fi
                fi
            done
        fi

        options=()
        if [ "${#profiles[@]}" -gt 0 ]; then
            options+=("🚀 Masuk ke Akun / Profile")
            options+=("📊 Cek Kuota & Usage Semua Akun")
        fi
        options+=("➕ Tambah Akun Baru")
        if [ "${#profiles[@]}" -gt 0 ]; then
            options+=("🔑 Login Ulang / Reset Token Profile")
            options+=("🗑️  Hapus Akun / Profile")
        fi
        options+=("❌ Keluar")

        if [ "${#active_profiles[@]}" -gt 0 ]; then
            active_info="🟢 Aktif: ${#active_profiles[@]} (${active_profiles[*]})"
        else
            active_info="⚪ Aktif: Tidak ada"
        fi

        if [ "${#profiles[@]}" -eq 0 ]; then
            header_text="Status: Belum ada akun yang terdaftar.
Status Aktif: $active_info
Gunakan panah [↑/↓] untuk memilih, Enter untuk mengonfirmasi."
        else
            header_text="Status: ${#profiles[@]} akun terdaftar (${profiles[*]})
Status Aktif: $active_info
Gunakan panah [↑/↓] untuk memilih, Enter untuk mengonfirmasi."
        fi

        choice=$(printf '%s\n' "${options[@]}" | fzf \
            --height=95% \
            --min-height=20 \
            --layout=reverse \
            --border=rounded \
            --border-label=" ⚡ Antigravity Profile Manager " \
            --border-label-pos=center \
            --padding=1 \
            --prompt="  Pilih Aksi ❯ " \
            --pointer="❯" \
            --header="$header_text") || { echo "Dibatalkan."; exit 0; }

        case "$choice" in
            "🚀 Masuk ke Akun / Profile")
                selected_profile=$(select_profile_fzf "Pilih Profile") || continue
                launch_profile "$selected_profile"
                exit 0
                ;;
            "📊 Cek Kuota & Usage Semua Akun")
                show_all_usage
                echo ""
                echo -n "Tekan Enter untuk kembali ke menu..."
                read -r
                ;;
            "➕ Tambah Akun Baru")
                echo -n "Masukkan nama profile baru: "
                read -r new_profile
                if [ -n "$new_profile" ]; then
                    launch_profile "$new_profile"
                    exit 0
                fi
                ;;
            "🔑 Login Ulang / Reset Token Profile")
                selected_profile=$(select_profile_fzf "Reset Token Profile") || continue
                relogin_profile "$selected_profile"
                exit 0
                ;;
            "🗑️  Hapus Akun / Profile")
                selected_profile=$(select_profile_fzf "Hapus Profile") || continue
                delete_profile "$selected_profile"
                ;;
            "❌ Keluar")
                exit 0
                ;;
        esac
    done
}

if [ "$#" -eq 0 ]; then
    interactive_menu
    exit 0
fi

case "$1" in
    preview)
        show_profile_preview "${2:-}"
        exit 0
        ;;
    -u|--usage|usage)
        show_all_usage
        ;;
    -l|--list|list)
        list_profiles
        ;;
    -h|--help|help)
        show_help
        ;;
    add)
        if [ -z "${2:-}" ]; then
            echo "Error: Nama profile wajib diisi."
            echo "Penggunaan: agy-profile add <nama_profile>"
            exit 1
        fi
        launch_profile "$2" "${@:3}"
        ;;
    rm)
        if [ -z "${2:-}" ]; then
            echo "Error: Nama profile wajib diisi."
            echo "Penggunaan: agy-profile rm <nama_profile>"
            exit 1
        fi
        delete_profile "$2"
        ;;
    *)
        launch_profile "$1" "${@:2}"
        ;;
esac
