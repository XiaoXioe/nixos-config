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

  hmConfig = hmOpts: {
    home.packages = with pkgs; [
      python3
      uv
    ];
  };
}
