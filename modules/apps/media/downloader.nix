{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.media.downloader";
  description = "Aria2 multi-protocol high-speed CLI downloader manager";

  preservation = {
    userDirectories = [ ".tdl" ];
  };

  hmConfig = {

    home.packages = with pkgs; [
      tdl
    ];

    programs.aria2 = {
      enable = true;
      settings = {
        max-connection-per-server = 4;
        split = 4;
        min-split-size = "10M";
        max-concurrent-downloads = 5;
        optimize-concurrent-downloads = true;

        continue = true;
        file-allocation = "falloc";
        allow-overwrite = false;
        auto-file-renaming = true;

        user-agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36";
      };
    };
  };
}
