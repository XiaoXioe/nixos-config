{
  config,
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "ai.agy-profile";
  description = "Multi-account profile launcher for Antigravity CLI";

  nixosConfig = {
    sops.secrets."doas-password" = {
      owner = config.my.user.name;
      mode = "0400";
    };
  };

  hmConfig = hmOpts: {
    home.packages = [
      (pkgs.writeShellApplication {
        name = "doas-agent";
        runtimeInputs = [
          pkgs.openssh
          pkgs.coreutils
        ];
        text = ''
          # Escaped arguments for safe remote execution
          QARGS=""
          for arg in "$@"; do
            QARGS="$QARGS $(printf '%q' "$arg")"
          done

          # Execute via SSH to localhost to escape bubblewrap PR_SET_NO_NEW_PRIVS restriction.
          # The remote end reads /run/secrets/doas-password directly to prevent exposing
          # the password in the process list (ps) on either the local or remote side.
          exec ssh -F /dev/null -i /home/klein-moretti/.ssh/id_ed25519 -o StrictHostKeyChecking=no klein-moretti@localhost \
            "env CMD_ARGS=$(printf '%q' "$QARGS") bash -c '
              DOAS_PASS_FILE=${hmOpts.osConfig.sops.secrets."doas-password".path}
              if [ ! -f \"\$DOAS_PASS_FILE\" ]; then
                echo \"doas-agent: secret file tidak ditemukan: \$DOAS_PASS_FILE\" >&2
                exit 1
              fi
              if command -v doas >/dev/null 2>&1; then
                script -q -c \"doas \$CMD_ARGS\" /dev/null < \"\$DOAS_PASS_FILE\"
              else
                sudo -S -p \"\" \$CMD_ARGS < \"\$DOAS_PASS_FILE\"
              fi
            '"
        '';
      })

      (pkgs.writeShellApplication {
        name = "agy-profile";
        runtimeInputs = [
          pkgs.bubblewrap
          pkgs.coreutils
          pkgs.fzf
        ];
        text = ''
                    REAL_HOME="$HOME"
                    AGY_DIR="$REAL_HOME/.gemini/antigravity-cli"
                    CRED_DIR_BASE="$AGY_DIR/credentials"

                    list_profiles() {
                        if [ -d "$CRED_DIR_BASE" ]; then
                            echo "Daftar akun/profile yang tersedia:"
                            found=0
                            for d in "$CRED_DIR_BASE"/*/; do
                                if [ -d "$d" ]; then
                                    pname="$(basename "$d")"
                                    if [ "$pname" != "*" ]; then
                                        echo "  - $pname"
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
                        rm -rf "$cred_dir"
                        echo "Profile '$profile_name' telah berhasil dihapus."
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
                            if [ -d "$CRED_DIR_BASE" ]; then
                                for d in "$CRED_DIR_BASE"/*/; do
                                    if [ -d "$d" ]; then
                                        pname="$(basename "$d")"
                                        [ "$pname" != "*" ] && profiles+=("$pname")
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

                            if [ ''${#profiles[@]} -eq 0 ]; then
                                header_text="Status: Belum ada akun yang terdaftar.
          Gunakan panah [↑/↓] untuk memilih, Enter untuk mengonfirmasi."
                            else
                                header_text="Status: ''${#profiles[@]} akun terdaftar (''${profiles[*]})
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
                                    selected_profile=$(printf '%s\n' "''${profiles[@]}" | fzf \
                                        --height=~40% \
                                        --min-height=12 \
                                        --layout=reverse \
                                        --border=rounded \
                                        --border-label=" 🚀 Masuk ke Profile " \
                                        --border-label-pos=center \
                                        --padding=1 \
                                        --prompt="  Pilih Profile ❯ " \
                                        --pointer="❯" \
                                        --header="Pilih akun yang ingin dijalankan:") || continue
                                    if [ -n "$selected_profile" ]; then
                                        launch_profile "$selected_profile"
                                    fi
                                    ;;
                                "➕ Tambah Akun Baru")
                                    echo ""
                                    read -r -p "Masukkan nama profile/akun baru: " raw_name
                                    new_name="$(echo "$raw_name" | xargs)"
                                    if [ -z "$new_name" ]; then
                                        echo "Nama profile tidak boleh kosong."
                                        sleep 1.5
                                        continue
                                    fi
                                    valid_regex="^[a-zA-Z0-9_-]+$"
                                    if [[ ! "$new_name" =~ $valid_regex ]]; then
                                        echo "Nama profile hanya boleh berisi huruf, angka, strip (-), atau underscore (_)."
                                        sleep 2
                                        continue
                                    fi
                                    launch_profile "$new_name"
                                    ;;
                                "🔑 Login Ulang / Reset Token Profile")
                                    selected_profile=$(printf '%s\n' "''${profiles[@]}" | fzf \
                                        --height=~40% \
                                        --min-height=12 \
                                        --layout=reverse \
                                        --border=rounded \
                                        --border-label=" 🔑 Reset Token Profile " \
                                        --border-label-pos=center \
                                        --padding=1 \
                                        --prompt="  Pilih Profile ❯ " \
                                        --pointer="❯" \
                                        --header="Perhatian: Token login akan dihapus agar agy meminta login ulang.") || continue
                                    if [ -n "$selected_profile" ]; then
                                        echo ""
                                        read -r -p "Reset token dan login ulang profile '$selected_profile'? [y/N]: " confirm
                                        if [[ "$confirm" =~ ^[yY]$ ]]; then
                                            relogin_profile "$selected_profile"
                                        fi
                                    fi
                                    ;;
                                "🗑️  Hapus Akun / Profile")
                                    selected_profile=$(printf '%s\n' "''${profiles[@]}" | fzf \
                                        --height=~40% \
                                        --min-height=12 \
                                        --layout=reverse \
                                        --border=rounded \
                                        --border-label=" 🗑️  Hapus Profile " \
                                        --border-label-pos=center \
                                        --padding=1 \
                                        --prompt="  Pilih Profile ❯ " \
                                        --pointer="❯" \
                                        --header="PERINGATAN: Credentials profile ini akan dihapus secara permanen.") || continue
                                    if [ -n "$selected_profile" ]; then
                                        echo ""
                                        read -r -p "Apakah Anda yakin ingin menghapus profile '$selected_profile'? [y/N]: " confirm
                                        if [[ "$confirm" =~ ^[yY]$ ]]; then
                                            delete_profile "$selected_profile"
                                            sleep 1.5
                                        fi
                                    fi
                                    ;;
                                "❌ Keluar")
                                    echo "Sampai jumpa!"
                                    exit 0
                                    ;;
                                *)
                                    exit 0
                                    ;;
                            esac
                        done
                    }

                    if [ $# -eq 0 ]; then
                        if [ -t 0 ] && [ -t 1 ]; then
                            interactive_menu
                        else
                            show_help
                            echo ""
                            list_profiles
                            exit 0
                        fi
                    fi

                    case "$1" in
                        -h|--help|help)
                            show_help
                            exit 0
                            ;;
                        -l|--list|list)
                            list_profiles
                            exit 0
                            ;;
                        add|--add)
                            if [ -z "''${2:-}" ]; then
                                echo "Error: Nama profile belum ditentukan."
                                echo "Penggunaan: agy-profile add <nama_profile>"
                                exit 1
                            fi
                            shift 1
                            launch_profile "$@"
                            ;;
                        rm|delete|--delete)
                            if [ -z "''${2:-}" ]; then
                                echo "Error: Nama profile belum ditentukan."
                                echo "Penggunaan: agy-profile rm <nama_profile>"
                                exit 1
                            fi
                            delete_profile "$2"
                            exit 0
                            ;;
                        *)
                            PROFILE_NAME="$1"
                            shift 1
                            launch_profile "$PROFILE_NAME" "$@"
                            ;;
                    esac
        '';
      })
    ];
  };
}
