{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "ai.agents.agy-profile";
  description = "Multi-account profile launcher for Antigravity CLI";

  hmConfig = {
    home.packages = [
      (selfLib.mkApp pkgs "agy-profile" (builtins.readFile ./scripts/agy-profile.sh) [
        pkgs.bubblewrap
        pkgs.coreutils
        pkgs.curl
        pkgs.fzf
        pkgs.jq
        pkgs.procps
        pkgs.psmisc
      ])
    ];
  };
}
