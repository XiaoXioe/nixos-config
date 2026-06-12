{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.my.user.scripts.compsize-scanner;

  compsize-scanner-pkg = pkgs.writeShellApplication {
    name = "compsize-scanner";

    runtimeInputs = with pkgs; [
      compsize
      gawk
      coreutils
      util-linux
    ];

    text = ''
      if [ $# -eq 0 ]; then
        echo "Penggunaan: sudo compsize-scanner <direktori>"
        echo "Contoh: sudo compsize-scanner /mnt/data_btrfs"
        echo "Contoh: sudo compsize-scanner ~"
        exit 1
      fi

      TARGET_DIR="$1"

      if [ ! -d "$TARGET_DIR" ]; then
        echo "Error: Direktori '$TARGET_DIR' tidak ditemukan."
        exit 1
      fi

      if [ "$(id -u)" -ne 0 ]; then
         echo "Peringatan: Script ini harus dijalankan dengan hak akses root."
         echo "Silakan ulangi dengan: sudo compsize-scanner $TARGET_DIR"
         exit 1
      fi

      (
        echo -e "PERCENT\tCOMPRESSED\tUNCOMPRESSED\tDIRECTORY"

        shopt -s dotglob nullglob

        for dir in "$TARGET_DIR"/*; do
          if [ -d "$dir" ] && [ ! -L "$dir" ]; then
            stats=$(compsize -x "$dir" 2>/dev/null | awk '/^TOTAL/ {print $2 "\t" $3 "\t" $4}' || true)

            if [ -n "$stats" ]; then
              clean_dir=$(echo "$dir" | tr -s '/')
              echo -e "$stats\t$clean_dir"
            fi
          fi
        done | sort -n
      ) | column -t
    '';
  };
in
{
  options.my.user.scripts.compsize-scanner = {
    enable = lib.mkEnableOption "Compsize wrapper script";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      compsize-scanner-pkg
    ];
  };
}
