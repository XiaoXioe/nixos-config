{ selfLib, ... }:

selfLib.mkModule {
  name = "apps.custom.flatpak-repo";
  description = "Flatpak service configuration, private applications, and repository sync service";

  preservation = {
    userDirectories = [
      ".BurpSuite"
    ];
  };

  flatpakCfg = {
    "com.portswigger.BurpSuitePro" = {
      enable = false;
      origin = "xiaoxioe-flatpak";
      binName = "burpsuitepro";
    };
    "io.github.xiaoyouchr.GhostDownloader" = {
      enable = true;
      origin = "xiaoxioe-flatpak";
      binName = "ghost-downloader";
    };
  };
}
