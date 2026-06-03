{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.my.custompkgs.git-commits;

  mkGitCommitScript =
    cmdName: commitType:
    pkgs.writeShellApplication {
      name = cmdName;
      runtimeInputs = [ pkgs.git ];
      text = ''
        if [ "$#" -eq 0 ]; then
          echo "Error: Masukkan pesan commit."
          echo "Penggunaan: ${cmdName} <pesan commit>"
          exit 1
        fi

        message="$*"
        git commit -m "${commitType}: $message"
      '';
    };

  # Men-generate masing-masing script
  gcfeat = mkGitCommitScript "gcfeat" "feat";
  gcfix = mkGitCommitScript "gcfix" "fix";
  gcchore = mkGitCommitScript "gcchore" "chore";
  gcdocs = mkGitCommitScript "gcdocs" "docs";
  gcstyle = mkGitCommitScript "gcstyle" "style";
  gcref = mkGitCommitScript "gcref" "refactor";
  gctest = mkGitCommitScript "gctest" "test";

  # Menggabungkan semua paket kecil di atas menjadi satu paket besar
  git-commits-bundle = pkgs.symlinkJoin {
    name = "git-conventional-commits-bundle";
    paths = [
      gcfeat
      gcfix
      gcchore
      gcdocs
      gcstyle
      gcref
      gctest
    ];
  };

in
{
  options.my.custompkgs.git-commits = {
    enable = lib.mkEnableOption "Git Conventional Commits helper scripts";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      git-commits-bundle
    ];
  };
}
