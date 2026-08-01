{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.dev.system.languages";
  description = "Programming language runtimes and environments";

  hmConfig = hmOpts: {
    home.packages = with pkgs; [
      python3
      uv
    ];
  };
}
