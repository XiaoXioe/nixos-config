{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "ai.agents.agy-profile";
  description = "Multi-account profile launcher for Antigravity CLI";

  hmConfig = hmOpts: {
    home.packages = [
      (selfLib.mkApp pkgs "agy-profile"
        ''
                    REAL_HOME="$HOME"
                    AGY_DIR="$REAL_HOME/.gemini/antigravity-cli"
                    CRED_DIR_BASE="$AGY_DIR/credentials"

                    is_profile_active() {
                        local pname="$1"
                        [ -z "$pname" ] && return 1
                        local cred_dir="$CRED_DIR_BASE/$pname"
                        pgrep -f "bwrap.*$cred_dir/" >/dev/null 2>&1
                    }

                    list_profiles() {
                        if [ -d "$CRED_DIR_BASE" ]; then
                            echo "Daftar akun/profile yang tersedia:"
                            found=0
                            for d in "$CRED_DIR_BASE"/*/; do
                                if [ -d "$d" ]; then
                                    pname="$(basename "$d")"
                                    if [ "$pname" != "*" ]; then
                                        if is_profile_active "$pname"; then
                                            echo "  - $pname (🟢 ACTIVE / IN USE)"
                                        else
                                            echo "  - $pname"
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
                        echo "Profile '$profile_name' telah berhasil dihapus."
                    }

                    select_profile_fzf() {
                        local label="$1"
                        local formatted_profiles=()
                        for p in "''${profiles[@]}"; do
                            if is_profile_active "$p"; then
                                formatted_profiles+=("$p [🟢 Aktif]")
                            else
                                formatted_profiles+=("$p [⚪ Tidak Aktif]")
                            fi
                        done

                        local choice
                        choice=$(printf '%s\n' "''${formatted_profiles[@]}" | fzf \
                            --height=~40% \
                            --min-height=12 \
                            --layout=reverse \
                            --border=rounded \
                            --border-label=" $label " \
                            --prompt="  Profile ❯ " \
                            --pointer="❯") || return 1

                        echo "''${choice%% [*}"
                    }

                    show_help() {
                        echo "Antigravity Profile Manager (agy-profile)"
                        echo ""
                        echo "Penggunaan:"
                        echo "  agy-profile                     Buka menu interaktif"
                        echo "  agy-profile <nama_profile>       Jalankan agy dengan profile tersebut"
                        echo "  agy-profile -l, --list, list    Tampilkan daftar profile"
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
                            if [ ''${#profiles[@]} -gt 0 ]; then
                                options+=("🚀 Masuk ke Akun / Profile")
                            fi
                            options+=("➕ Tambah Akun Baru")
                            if [ ''${#profiles[@]} -gt 0 ]; then
                                options+=("🔑 Login Ulang / Reset Token Profile")
                                options+=("🗑️  Hapus Akun / Profile")
                            fi
                            options+=("❌ Keluar")

                            if [ ''${#active_profiles[@]} -gt 0 ]; then
                                active_info="🟢 Aktif: ''${#active_profiles[@]} (''${active_profiles[*]})"
                            else
                                active_info="⚪ Aktif: Tidak ada"
                            fi

                            if [ ''${#profiles[@]} -eq 0 ]; then
                                header_text="Status: Belum ada akun yang terdaftar.
          Status Aktif: $active_info
          Gunakan panah [↑/↓] untuk memilih, Enter untuk mengonfirmasi."
                            else
                                header_text="Status: ''${#profiles[@]} akun terdaftar (''${profiles[*]})
          Status Aktif: $active_info
          Gunakan panah [↑/↓] untuk memilih, Enter untuk mengonfirmasi."
                            fi

                            choice=$(printf '%s\n' "''${options[@]}" | fzf \
                                --height=~50% \
                                --min-height=15 \
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
                        -l|--list|list)
                            list_profiles
                            ;;
                        -h|--help|help)
                            show_help
                            ;;
                        add)
                            if [ -z "''${2:-}" ]; then
                                echo "Error: Nama profile wajib diisi."
                                echo "Penggunaan: agy-profile add <nama_profile>"
                                exit 1
                            fi
                            launch_profile "$2" "''${@:3}"
                            ;;
                        rm)
                            if [ -z "''${2:-}" ]; then
                                echo "Error: Nama profile wajib diisi."
                                echo "Penggunaan: agy-profile rm <nama_profile>"
                                exit 1
                            fi
                            delete_profile "$2"
                            ;;
                        *)
                            launch_profile "$1" "''${@:2}"
                            ;;
                    esac
        ''
        [
          pkgs.bubblewrap
          pkgs.coreutils
          pkgs.fzf
          pkgs.procps
          pkgs.psmisc
        ]
      )
    ];
  };
}
