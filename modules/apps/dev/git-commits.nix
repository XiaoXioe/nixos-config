{
  pkgs,
  selfLib,
  ...
}:
let
  mkGitCommitScript =
    cmdName: commitType:
    pkgs.writeShellApplication {
      name = cmdName;
      runtimeInputs = [ pkgs.git ];
      text = "
      if [ \"$#\" -eq 0 ]; then 
        exit 1; 
      fi;
      git commit -m \"${commitType}: $*\";";
    };
in
selfLib.mkModule {
  name = "apps.dev.git-commits";
  description = "Git Conventional Commits helper scripts";

  hmConfig = hmOpts: {
    home.packages = [
      (pkgs.symlinkJoin {
        name = "git-conventional-commits-bundle";
        paths = [
          (mkGitCommitScript "gcfeat" "feat")
          (mkGitCommitScript "gcfix" "fix")
          (mkGitCommitScript "gcchore" "chore")
          (mkGitCommitScript "gcdocs" "docs")
          (mkGitCommitScript "gcstyle" "style")
          (mkGitCommitScript "gcref" "refactor")
          (mkGitCommitScript "gctest" "test")
        ];
      })
    ];
  };
}
