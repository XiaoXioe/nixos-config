{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.my.custompkgs.compsize-wrapper;

  compsize-scanner-pkg = pkgs.writeShellApplication {
    name = "compsize-scanner";

    # Do not use 'sudo' here — the script itself handles elevated permissions.
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
         echo "⚠️ Peringatan: Script ini harus dijalankan dengan hak akses root agar bisa membaca metadata Btrfs."
         echo "Silakan ulangi dengan: sudo compsize-scanner $TARGET_DIR"
         exit 1
      fi

      (
        echo -e "PERCENT\tCOMPRESSED\tUNCOMPRESSED\tDIRECTORY"

        shopt -s dotglob nullglob

        for dir in "$TARGET_DIR"/*; do
          if [ -d "$dir" ] && [ ! -L "$dir" ]; then

            # 1. Add -x flag to stay safe from FUSE/virtual mounts
            stats=$(compsize -x "$dir" 2>/dev/null | awk '/^TOTAL/ {print $2 "\t" $3 "\t" $4}' || true)

            if [ -n "$stats" ]; then
              # 2. Normalize double slashes (e.g. //nix → /nix)
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
  options.my.custompkgs.compsize-wrapper = {
    enable = lib.mkEnableOption "Compsize wrapper bin";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      compsize-scanner-pkg
    ];
  };
}
