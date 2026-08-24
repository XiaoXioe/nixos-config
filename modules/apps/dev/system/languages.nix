{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.dev.system.languages";
  description = "Programming language runtimes and environments";

  preservation = {
    userDirectories = [
      ".java"
      ".npm"
    ];
  };

  nixosConfig = {
    environment.localBinInPath = true;
  };

  hmConfig = {
    home.sessionPath = [
      "$HOME/.local/bin"
    ];

    home.packages = selfLib.fetchCachePinned [
      pkgs.python3
      pkgs.uv
      "ruff"
    ];
  };
}
