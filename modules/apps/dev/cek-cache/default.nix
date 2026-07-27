{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.dev.cek-cache";
  description = "Check package in /nix/store";

  hmConfig = hmOpts: {
    home.packages = [
      (pkgs.writeShellApplication {
        name = "cek-cache";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.nix
          pkgs.gnugrep
        ];
        text = ''
          if [ "$#" -eq 0 ]; then
            echo "Error: Masukkan nama paket atau perintah."
            echo "Penggunaan: cek-cache <perintah>"
            exit 1
          fi

          bin_path=$(command -v "$1" || true)

          if [ -z "$bin_path" ]; then
            echo "Error: Perintah '$1' tidak ditemukan."
            exit 1
          fi

          real_path=$(readlink -f "$bin_path")

          if [[ ! "$real_path" =~ ^/nix/store/ ]]; then
            echo "Error: Path bukan berasal dari Nix store ($real_path)"
            exit 1
          fi

          store_path=$(echo "$real_path" | grep -oE '^/nix/store/[^/]+')

          if [ -z "$store_path" ]; then
            echo "Error: Gagal memproses path Nix store."
            exit 1
          fi

          echo "Mengecek signatures untuk: $store_path"
          nix path-info --sigs "$store_path"
        '';
      })
    ];
  };
}
