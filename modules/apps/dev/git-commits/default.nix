{
  pkgs,
  lib,
  selfLib,
  ...
}:
let
  commitTypes = [
    "gcfeat"
    "gcfix"
    "gcchore"
    "gcdocs"
    "gcstyle"
    "gcref"
    "gctest"
  ];
in
selfLib.mkModule {
  name = "apps.dev.git-commits";
  description = "Git Conventional Commits helper scripts";

  hmConfig = hmOpts: {
    home.packages = [
      (
        (
          (selfLib.shell {
            inherit pkgs;
            lib = pkgs.lib;
          }).mkApp
          "git-commit-helper"
          ''
            cmd="$(basename "$0")"
            case "$cmd" in
              gcfeat) category="feat" ;;
              gcfix) category="fix" ;;
              gcchore) category="chore" ;;
              gcdocs) category="docs" ;;
              gcstyle) category="style" ;;
              gcref) category="refactor" ;;
              gctest) category="test" ;;
              *) category="$cmd" ;;
            esac

            if [ "$#" -eq 0 ]; then
              exit 1
            fi
            exec git commit -m "''${category}: $*"
          ''
          [ pkgs.git ]
        ).overrideAttrs
        (old: {
          buildCommand =
            old.buildCommand
            + "\n"
            + lib.concatMapStrings (cmd: ''
              ln -s git-commit-helper $out/bin/${cmd}
            '') commitTypes;
        })
      )
    ];
  };
}
