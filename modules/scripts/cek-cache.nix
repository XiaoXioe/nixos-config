{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "scripts.cek-cache";
  description = "Check package in /nix/store";

  hmConfig = {
    home.packages = [
      (pkgs.writeShellApplication {
        name = "cek-cache";
        runtimeInputs = [ pkgs.coreutils pkgs.nix pkgs.gnugrep ];
        text = ''
          if [ "$#" -eq 0 ]; then echo "Usage: cek-cache <perintah>"; exit 1; fi
          bin_path=$(command -v "$1" || true)
          if [ -z "$bin_path" ]; then echo "Error: '$1' not found."; exit 1; fi
          real_path=$(readlink -f "$bin_path")
          if [[ ! "$real_path" =~ ^/nix/store/ ]]; then echo "Error: Not in Nix store."; exit 1; fi
          store_path=$(echo "$real_path" | grep -oE '^/nix/store/[^/]+')
          nix path-info --sigs "$store_path"
        '';
      })
    ];
  };
}
