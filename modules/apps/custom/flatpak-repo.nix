{ selfLib, ... }:

selfLib.mkModule {
  name = "apps.custom.flatpak-repo";
  description = "Flatpak service configuration, private applications, and repository sync service";

  preservation = {
    cleanupOnDisable = true;
    userDirectories = [
      ".BurpSuite"
    ];
  };

  flatpakCfg = {
    "com.portswigger.BurpSuitePro" = {
      enable = true;
      origin = "xiaoxioe-flatpak";
      binName = "burpsuitepro";
    };
    "io.github.xiaoyouchr.GhostDownloader" = {
      enable = false;
      origin = "xiaoxioe-flatpak";
      binName = "ghost-downloader";
    };
  };
}
