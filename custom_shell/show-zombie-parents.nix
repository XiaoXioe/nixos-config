{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.system.show-zombie-parents;

  # Menggunakan writeShellScriptBin agar langsung menghasilkan binary di /bin
  show-zombie-parents-pkg = pkgs.writeShellScriptBin "show-zombie-parents" ''
    # Tambahkan pengecekan agar tidak error jika tidak ada zombie
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
  options.my.system.show-zombie-parents = {
    enable = selfLib.mkBoolOpt false "Identify zombie/defunct processes";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      show-zombie-parents-pkg
    ];
  };
}
