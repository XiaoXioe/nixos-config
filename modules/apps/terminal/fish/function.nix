{ ... }: {
  programs.fish.functions = {
    "," = {
      body = ''
        if not set -q argv[1]
            echo "Usage: , <package> [args...]"
            return 1
        end
        nix run "nixpkgs#$argv[1]" -- $argv[2..-1]
      '';
    };

    ",," = {
      body = ''
        if not set -q argv[1]
            echo "Usage: ,, <packages...>"
            return 1
        end
        nix shell "nixpkgs#"$argv
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
