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

  hmConfig = hmOpts: {
    home.sessionPath = [
      "$HOME/.local/bin"
    ];

    home.packages = with pkgs; [
      python3
      uv
    ];
  };
}
