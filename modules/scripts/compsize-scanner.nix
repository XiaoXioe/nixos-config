{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "scripts.compsize-scanner";
  description = "Compsize wrapper script";

  hmConfig = {
    home.packages = [
      (pkgs.writeShellApplication {
        name = "compsize-scanner";
        runtimeInputs = with pkgs; [ compsize gawk coreutils util-linux ];
        text = ''
          if [ $# -eq 0 ]; then echo "Usage: sudo compsize-scanner <dir>"; exit 1; fi
          if [ "$(id -u)" -ne 0 ]; then echo "Root required."; exit 1; fi
          (
            echo -e "PERCENT\tCOMPRESSED\tUNCOMPRESSED\tDIRECTORY"
            shopt -s dotglob nullglob
            for dir in "$1"/*; do
              if [ -d "$dir" ] && [ ! -L "$dir" ]; then
                stats=$(compsize -x "$dir" 2>/dev/null | awk '/^TOTAL/ {print $2 "\t" $3 "\t" $4}' || true)
                if [ -n "$stats" ]; then echo -e "$stats\t$(echo "$dir" | tr -s '/') "; fi
              fi
            done | sort -n
          ) | column -t
        '';
      })
    ];
  };
}
