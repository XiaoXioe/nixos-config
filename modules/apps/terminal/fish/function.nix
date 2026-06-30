{ ... }: {
  programs.fish.functions = {
    "," = {
      wraps = "nix run";
      body = ''
        if not set -q argv[1]
            echo "Usage: , <package> [args...]"
            return 1
        end
        env NIXPKGS_ALLOW_UNFREE=1 NIXPKGS_ALLOW_INSECURE=1 nix run --impure "nixpkgs#$argv[1]" -- $argv[2..-1]
      '';
    };

    ",," = {
      wraps = "nix shell";
      body = ''
        if not set -q argv[1]
            echo "Usage: ,, <packages...>"
            return 1
        end
        env NIXPKGS_ALLOW_UNFREE=1 NIXPKGS_ALLOW_INSECURE=1 nix shell --impure "nixpkgs#"$argv
      '';
    };

    agy-profile = {
      body = ''
        if not set -q argv[1]
            echo "Penggunaan: agy-profile <nama_profile>"
            return 1
        end
        set -l PROFILE_NAME $argv[1]
        set -l PROFILE_HOME $HOME/.config/agy-profiles/$PROFILE_NAME

        # Pastikan direktori tujuan ada
        mkdir -p $PROFILE_HOME/.gemini/antigravity-cli

        # Hubungkan config (berisi skills, rules, dan mcp_config.json) dari home asli
        if not test -L $PROFILE_HOME/.gemini/config
            rm -rf $PROFILE_HOME/.gemini/config
            ln -sfn $HOME/.gemini/config $PROFILE_HOME/.gemini/config
        end

        # Hubungkan settings.json agar konfigurasi editor/cli sama
        if not test -L $PROFILE_HOME/.gemini/antigravity-cli/settings.json
            rm -f $PROFILE_HOME/.gemini/antigravity-cli/settings.json
            ln -sfn $HOME/.gemini/antigravity-cli/settings.json $PROFILE_HOME/.gemini/antigravity-cli/settings.json
        end

        # Hubungkan data proyek/percakapan agar riwayat (brain, conversations, history, knowledge) terbagi
        for item in brain conversations history.jsonl knowledge
            if not test -L $PROFILE_HOME/.gemini/antigravity-cli/$item
                rm -rf $PROFILE_HOME/.gemini/antigravity-cli/$item
                ln -sfn $HOME/.gemini/antigravity-cli/$item $PROFILE_HOME/.gemini/antigravity-cli/$item
            end
        end

        echo "Menjalankan agy untuk profile: $PROFILE_NAME"
        env HOME=$PROFILE_HOME DBUS_SESSION_BUS_ADDRESS=unix:path=/dev/null agy
      '';
    };

    agy-ide-profile = {
      body = ''
        if not set -q argv[1]
            echo "Penggunaan: agy-ide-profile <nama_profile>"
            return 1
        end
        set -l PROFILE_NAME $argv[1]
        set -l PROFILE_DIR $HOME/.config/antigravity-ide-profiles/$PROFILE_NAME

        # Pastikan direktori profil ada
        mkdir -p $PROFILE_DIR

        # Hubungkan konfigurasi penting dari home asli
        if not test -L $PROFILE_DIR/.gemini
            ln -sfn $HOME/.gemini $PROFILE_DIR/.gemini
        end
        if not test -L $PROFILE_DIR/.ssh
            ln -sfn $HOME/.ssh $PROFILE_DIR/.ssh
        end
        if not test -L $PROFILE_DIR/.gitconfig
            ln -sfn $HOME/.gitconfig $PROFILE_DIR/.gitconfig
        end

        echo "Menjalankan Antigravity IDE dengan profile: $PROFILE_NAME"
        env HOME=$PROFILE_DIR antigravity-ide
      '';
    };

    fish_should_add_to_history = {
      body = ''
        # 1. Abaikan perintah yang diawali dengan spasi (perilaku default Fish)
        string match -qr '^\s' -- $argv; and return 1

        # 2. Abaikan perintah yang mengandung kata kunci sensitif (case-insensitive)
        if string match -qi "*password*" -- $argv
            or string match -qi "*token*" -- $argv
            or string match -qi "*secret*" -- $argv
            or string match -qi "*privatekey*" -- $argv
            return 1
        end

        # 3. Cari file blacklist
        set -l blacklist_file $HOME/.config/fish/history_blacklist
        if test -f $blacklist_file
            # Dapatkan nama perintah utama (kata pertama, dibersihkan dari path direktori jika ada)
            set -l cmd_path (string split -m 1 " " -- (string trim $argv))[1]
            set -l cmd (basename -- $cmd_path; or echo $cmd_path)

            # Baca file blacklist, abaikan baris kosong dan komentar (#)
            set -l blacklist (string match -rv '^\s*(#|$)' < $blacklist_file)
            if contains -- $cmd $blacklist
                return 1
            end
        end

        return 0
      '';
    };
  };
}
