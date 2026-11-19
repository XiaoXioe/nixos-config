#!/usr/bin/env bash
set -euo pipefail

REAL_HOME="$HOME"
AGY_DIR="$REAL_HOME/.gemini/antigravity-cli"
CRED_DIR_BASE="$AGY_DIR/credentials"
CACHE_DIR="/tmp/agy-profile-cache-$USER"
CACHE_TTL=60
MAX_PARALLEL_JOBS=4
mkdir -p "$CACHE_DIR"

SELF_CMD="agy-profile"
if [ -x "${BASH_SOURCE[0]}" ]; then
    SELF_CMD="${BASH_SOURCE[0]}"
fi

ensure_profile_files() {
    local cred_dir="$1"
    local f
    for f in antigravity-oauth-token installation_id jetski_state.pbtxt; do
        if [ ! -f "$cred_dir/$f" ]; then
            touch "$cred_dir/$f"
        fi
    done
    return 0
}

clear_profile_cache() {
    local raw_pname="${1:-}"
    local pname="${raw_pname%% (*}"
    pname="${pname%% *}"
    [ -z "$pname" ] && return 0
    rm -f "$CACHE_DIR/$pname.usage.json" "$CACHE_DIR/$pname.json"
}

is_profile_active() {
    local pname="$1"
    [ -z "$pname" ] && return 1
    pgrep -f "bwrap.*AGY_PROFILE_SESSION $pname --die-with-parent" >/dev/null 2>&1
}

get_profile_email() {
    local pname="$1"
    [ -z "$pname" ] && echo "Unknown Email" && return 0
    local cred_dir="$CRED_DIR_BASE/$pname"
    local cred_file="$cred_dir/antigravity-oauth-token"
    local email_file="$cred_dir/email"

    if [ ! -f "$cred_file" ]; then
        echo "Belum Login"
        return 0
    fi

    if [ -s "$email_file" ]; then
        cat "$email_file"
        return 0
    fi

    local token
    token=$(jq -r '.token.access_token // empty' "$cred_file" 2>/dev/null || true)
    local email=""
    if [ -n "$token" ]; then
        email=$(curl -s -m 2 -H "Authorization: Bearer $token" "https://www.googleapis.com/oauth2/v3/userinfo" 2>/dev/null | jq -r '.email // empty' 2>/dev/null || true)
    fi

    if [ -n "$email" ]; then
        echo "$email" > "$email_file" 2>/dev/null || true
        echo "$email"
        return 0
    fi

    echo "Email Tidak Diketahui"
}

fetch_profile_quota() {
    local pname="$1"
    local force_refresh="${2:-0}"
    local cred_dir="$CRED_DIR_BASE/$pname"
    local cred_file="$cred_dir/antigravity-oauth-token"
    local cache_file="$CACHE_DIR/$pname.usage.json"

    if [ ! -s "$cred_file" ]; then
        echo '{"error": "Belum login atau token tidak ditemukan"}'
        return 1
    fi

    if [ "$force_refresh" -ne 1 ] && [ -f "$cache_file" ]; then
        local mtime
        mtime=$(stat -c %Y "$cache_file" 2>/dev/null || echo 0)
        local now
        now=$(date +%s)
        if [ $((now - mtime)) -lt "$CACHE_TTL" ] && jq -e '.status == "SUCCESS" and (.command.data.groups | type == "array")' "$cache_file" >/dev/null 2>&1; then
            cat "$cache_file"
            return 0
        fi
    fi

    ensure_profile_files "$cred_dir"

    local res=""
    res=$(timeout 15 bwrap \
        --dev-bind / / \
        --bind "$cred_dir/antigravity-oauth-token" "$AGY_DIR/antigravity-oauth-token" \
        --bind "$cred_dir/installation_id" "$AGY_DIR/installation_id" \
        --bind "$cred_dir/jetski_state.pbtxt" "$AGY_DIR/jetski_state.pbtxt" \
        --setenv DBUS_SESSION_BUS_ADDRESS unix:path=/dev/null \
        agy -p "/usage" --output-format json 2>/dev/null || true)

    if printf '%s\n' "$res" | jq -e '.status == "SUCCESS" and (.command.data.groups | type == "array")' >/dev/null 2>&1; then
        local tmp_file
        tmp_file=$(mktemp "$CACHE_DIR/.$pname.usage.XXXXXX")
        printf '%s\n' "$res" > "$tmp_file"
        mv -f "$tmp_file" "$cache_file"

        if [ ! -s "$cred_dir/email" ]; then
            local token
            token=$(jq -r '.token.access_token // empty' "$cred_file" 2>/dev/null || true)
            if [ -n "$token" ]; then
                local email
                email=$(curl -s -m 2 -H "Authorization: Bearer $token" "https://www.googleapis.com/oauth2/v3/userinfo" 2>/dev/null | jq -r '.email // empty' 2>/dev/null || true)
                if [ -n "$email" ]; then
                    printf '%s\n' "$email" > "$cred_dir/email" 2>/dev/null || true
                fi
            fi
        fi

        printf '%s\n' "$res"
        return 0
    fi

    local err_msg=""
    err_msg=$(printf '%s\n' "$res" | jq -r '.error // .response // empty' 2>/dev/null | head -n 1 || true)
    if [ -n "$err_msg" ]; then
        jq -nc --arg err "$err_msg" '{"error": $err}'
    else
        echo '{"error": "Token expired, timeout, atau login diperlukan"}'
    fi
    return 1
}

show_profile_preview() {
    local raw_pname="$1"
    local force_refresh="${2:-0}"
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
    quota_json=$(fetch_profile_quota "$pname" "$force_refresh" 2>/dev/null || true)

    if printf '%s\n' "$quota_json" | jq -e '.status == "SUCCESS" and (.command.data.groups | type == "array")' >/dev/null 2>&1; then
        echo "📊 MODEL QUOTA & LIMITS:"
        printf '%s\n' "$quota_json" | jq -r '
            def pad($n):
                if length < $n then . + (" " * ($n - length)) else . end;
            def lpad($n):
                if length < $n then (" " * ($n - length)) + . else . end;
            def bar($pct):
                (($pct / 10) | round) as $filled |
                (if $filled < 0 then 0 elif $filled > 10 then 10 else $filled end) as $f |
                "[" + ("█" * $f) + ("░" * (10 - $f)) + "]";
            def status_dot($pct):
                if $pct >= 50 then "🟢"
                elif $pct >= 20 then "🟡"
                else "🔴"
                end;
            def fmt_rel:
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
                end;
            def fmt_local:
                fromdateiso8601 | strflocaltime("%d %b %H:%M %Z");
            def short_bucket_name($gname):
                (.name // .window // "Limit")
                | sub(" Remaining$"; "")
                | sub("^Five Hour "; "5-Hour ")
                | if startswith($gname + " ") then .[($gname | length) + 1:] else . end;

            [
                .command.data.groups[]? |
                (.name // "Unknown Group") as $gname |
                "  🔹 " + $gname + "\n" +
                (if ((.description // "") | startswith("Models within this group: ")) then
                    "     (" + (.description | sub("^Models within this group: "; "")) + ")\n"
                 else "" end) +
                ((.buckets // []) | map(
                    if (.disabled // false) then
                        "     • " + (short_bucket_name($gname) | pad(13)) + " ⛔ Disabled"
                    elif .remaining_fraction == null then
                        "     • " + (short_bucket_name($gname) | pad(13)) + " ⚪ N/A"
                    else
                        (.remaining_fraction * 100 | round) as $pct |
                        "     • " + (short_bucket_name($gname) | pad(13)) + " " +
                        status_dot($pct) + " " + bar($pct) + " " + ((($pct | tostring) + "%") | lpad(4)) +
                        (if .reset_time then
                            (.reset_time | fmt_rel) as $rel |
                            if $rel == "Ready" then "  (Reset: Ready)"
                            else "  (Reset: dlm " + $rel + " · " + (.reset_time | fmt_local) + ")"
                            end
                         else "" end)
                    end
                ) | join("\n"))
            ] | join("\n\n")
        '

        local cache_file="$CACHE_DIR/$pname.usage.json"
        if [ -f "$cache_file" ]; then
            local mtime now age
            mtime=$(stat -c %Y "$cache_file" 2>/dev/null || echo 0)
            now=$(date +%s)
            age=$((now - mtime))
            echo ""
            if [ "$age" -le 2 ]; then
                echo "  🕒 Diperbarui: baru saja"
            else
                echo "  🕒 Diperbarui: ${age}s lalu (cache ${CACHE_TTL}s)"
            fi
        fi
    else
        local err_msg=""
        err_msg=$(printf '%s\n' "$quota_json" | jq -r '.error // empty' 2>/dev/null || true)
        echo "⚠️ STATUS QUOTA:"
        if [ -n "$err_msg" ]; then
            echo "  🔴 $err_msg"
        else
            echo "  🔴 Token Expired atau Login Diperlukan."
        fi
        echo "  Jalankan profil 'agy-profile $pname' untuk login ulang."
    fi
}

show_all_usage() {
    local force_refresh="${1:-0}"
    echo "📊 MENAMPILKAN USAGE & KUOTA MODEL UNTUK SEMUA AKUN:"
    echo ""

    if [ ! -d "$CRED_DIR_BASE" ]; then
        echo "Belum ada profile terdaftar."
        return 0
    fi

    local all_profiles=()
    local d pname
    for d in "$CRED_DIR_BASE"/*/; do
        if [ -d "$d" ]; then
            pname="$(basename "$d")"
            if [ "$pname" != "*" ]; then
                all_profiles+=("$pname")
            fi
        fi
    done

    if [ "${#all_profiles[@]}" -eq 0 ]; then
        echo "Belum ada profile terdaftar."
        return 0
    fi

    local tmp_dir
    tmp_dir=$(mktemp -d "$CACHE_DIR/.usage-batch.XXXXXX")

    local running=0
    for pname in "${all_profiles[@]}"; do
        show_profile_preview "$pname" "$force_refresh" > "$tmp_dir/$pname.out" 2>&1 &
        running=$((running + 1))
        if [ "$running" -ge "$MAX_PARALLEL_JOBS" ]; then
            wait -n || true
            running=$((running - 1))
        fi
    done
    wait || true

    for pname in "${all_profiles[@]}"; do
        if [ -f "$tmp_dir/$pname.out" ]; then
            cat "$tmp_dir/$pname.out"
        fi
        echo ""
        echo "──────────────────────────────────────────────────────────────────"
        echo ""
    done

    rm -rf "$tmp_dir"
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

    ensure_profile_files "$cred_dir"

    echo "Menjalankan agy untuk profile: $profile_name (namespace mode)"
    exec bwrap \
        --dev-bind / / \
        --bind "$cred_dir/antigravity-oauth-token" "$AGY_DIR/antigravity-oauth-token" \
        --bind "$cred_dir/installation_id" "$AGY_DIR/installation_id" \
        --bind "$cred_dir/jetski_state.pbtxt" "$AGY_DIR/jetski_state.pbtxt" \
        --setenv DBUS_SESSION_BUS_ADDRESS unix:path=/dev/null \
        --setenv AGY_PROFILE_SESSION "$profile_name" \
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
    rm -f "$cred_dir/antigravity-oauth-token" "$cred_dir/installation_id" "$cred_dir/jetski_state.pbtxt" "$cred_dir/email"
    clear_profile_cache "$profile_name"
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
    clear_profile_cache "$profile_name"
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
        --header="↑/↓: Pilih | Enter: Konfirmasi | Ctrl-R: Refresh Kuota" \
        --prompt="  Profile ❯ " \
        --pointer="❯" \
        --bind="ctrl-r:execute-silent(\"$SELF_CMD\" clear-cache {})+refresh-preview" \
        --preview="\"$SELF_CMD\" preview {}" \
        --preview-window=right:60%:wrap) || return 1

    echo "${choice%% (*}"
}

show_help() {
    echo "Antigravity Profile Manager (agy-profile)"
    echo ""
    echo "Penggunaan:"
    echo "  agy-profile                          Buka menu interaktif dengan preview kuota model"
    echo "  agy-profile <nama_profile>           Jalankan agy dengan profile tersebut"
    echo "  agy-profile -u, --usage, usage [-r]  Tampilkan penggunaan/kuota model semua akun"
    echo "                                       Gunakan -r / --refresh untuk melewati cache"
    echo "  agy-profile -l, --list, list         Tampilkan daftar profile & email"
    echo "  agy-profile add <nama_profile>       Tambah profile baru & jalankan"
    echo "  agy-profile rm <nama_profile>        Hapus profile"
    echo "  agy-profile -h, --help, help         Tampilkan bantuan ini"
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
                local refresh_flag=0
                while true; do
                    show_all_usage "$refresh_flag"
                    echo ""
                    echo -n "Tekan [r] + Enter untuk refresh, atau Enter untuk kembali ke menu: "
                    read -r action_key || break
                    case "$action_key" in
                        r|R)
                            refresh_flag=1
                            clear 2>/dev/null || true
                            ;;
                        *)
                            break
                            ;;
                    esac
                done
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
        if [ "${2:-}" = "-r" ] || [ "${2:-}" = "--refresh" ]; then
            show_profile_preview "${3:-}" 1
        elif [ "${3:-}" = "-r" ] || [ "${3:-}" = "--refresh" ]; then
            show_profile_preview "${2:-}" 1
        else
            show_profile_preview "${2:-}" 0
        fi
        exit 0
        ;;
    clear-cache)
        clear_profile_cache "${2:-}"
        exit 0
        ;;
    -u|--usage|usage)
        if [ "${2:-}" = "-r" ] || [ "${2:-}" = "--refresh" ]; then
            show_all_usage 1
        else
            show_all_usage 0
        fi
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
