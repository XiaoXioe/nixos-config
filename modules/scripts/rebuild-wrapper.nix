{
  config,
  pkgs,
  lib,
  allUsers,
  selfLib,
  ...
}:
let
  userList = lib.mapAttrsToList (name: _: name) allUsers;
  rebuild-all-pkg = pkgs.writeShellScriptBin "rebuild-all" ''
    set -e
    DO_SYSTEM=true
    DO_HOME=true
    SPECIFIC_USER=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        -s|--system) DO_SYSTEM=true; DO_HOME=false; shift ;;
        -u|--user) DO_SYSTEM=false; DO_HOME=true; if [ -n "$2" ] && [[ "$2" != -* ]]; then SPECIFIC_USER="$2"; shift 2; else echo "Error: Argumen hilang."; exit 1; fi ;;
        -a|--all) DO_SYSTEM=true; DO_HOME=true; shift ;;
        *) echo "Opsi tidak dikenal: $1"; exit 1 ;;
      esac
    done
    SOURCE_DIR=$(pwd)
    if [ ! -f "$SOURCE_DIR/flake.nix" ]; then SOURCE_DIR="${config.my.user.flakePath}"; fi
    if [ "$DO_SYSTEM" = true ]; then ${pkgs.nh}/bin/nh os switch "$SOURCE_DIR"; fi
    if [ "$DO_HOME" = true ]; then
      TARGET_USERS="''${SPECIFIC_USER:-${lib.concatStringsSep " " userList}}"
      for user in $TARGET_USERS; do
        BACKUP_EXT="backup-$(date +%s)"
        if [ "$USER" = "$user" ]; then ${pkgs.nh}/bin/nh home switch -b "$BACKUP_EXT" "$SOURCE_DIR"
        else
          ACTIVATE_SCRIPT=$(nix build "$SOURCE_DIR#homeConfigurations.\"$user@${config.my.hostname}\".activationPackage" --no-link --print-out-paths)
          sudo -u "$user" -H env HOME_MANAGER_BACKUP_EXT="$BACKUP_EXT" "$ACTIVATE_SCRIPT/activate"
        fi
      done
    fi
  '';
in
selfLib.mkModule {
  name = "scripts.rebuild-wrapper";
  description = "automated system and user rebuild script";
  hmConfig = { home.packages = [ rebuild-all-pkg ]; };
}
