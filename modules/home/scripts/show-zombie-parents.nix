{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.my.user.scripts.show-zombie-parents;

  show-zombie-parents-pkg = pkgs.writeShellScriptBin "show-zombie-parents" ''
    ZOMBIE_PPIDS=$(ps -A -ostat,ppid | grep -e '[zZ]' | awk '{ print $2 }' | uniq)

    if [ -n "$ZOMBIE_PPIDS" ]; then
        echo "Found zombie parents:"
        echo "$ZOMBIE_PPIDS" | xargs ${pkgs.procps}/bin/ps -p
    else
        echo "No zombie processes found."
    fi
  '';
in
{
  options.my.user.scripts.show-zombie-parents = {
    enable = lib.mkEnableOption "Identify zombie/defunct processes";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      show-zombie-parents-pkg
    ];
  };
}
