{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.system.compsize-wrapper;

  compsize-scanner-pkg = pkgs.writeShellApplication {
    name = "compsize-scanner";

    # HAPUS 'sudo' dari sini. Kita akan mengeksekusi script-nya yang menggunakan sudo.
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

            # 1. Tambahkan opsi -x agar aman dari folder FUSE/Virtual
            stats=$(compsize -x "$dir" 2>/dev/null | awk '/^TOTAL/ {print $2 "\t" $3 "\t" $4}' || true)

            if [ -n "$stats" ]; then
              # 2. Merapikan garis miring ganda (misal //nix menjadi /nix)
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
  options.my.system.compsize-wrapper = {
    enable = selfLib.mkBoolOpt false "Compsize wrapper bin";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      compsize-scanner-pkg
    ];
  };
}
