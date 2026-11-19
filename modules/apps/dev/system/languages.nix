{
  pkgs,
  pkgs-unstable,
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
    home.packages = [
      pkgs.python3
      pkgs.uv
      pkgs-unstable.ruff
    ];
  };
}
