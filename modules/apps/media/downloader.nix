{
  pkgs,
  selfLib,
  ...
}:

let
  tdlInfo = selfLib.appVersions.tdl;
  aria2Info = selfLib.appVersions.aria2;

  tdlNative = (selfLib.mkNativeApp pkgs) {
    name = "tdl";
    inherit (tdlInfo) version;
    src = selfLib.fetchApp pkgs "tdl";
    execPath = "tdl";
    binName = "tdl";
    isDesktop = false;
  };

  aria2Native = (selfLib.mkNativeApp pkgs) {
    name = "aria2";
    inherit (aria2Info) version;
    src = selfLib.fetchApp pkgs "aria2";
    execPath = "usr/bin/aria2c";
    binName = "aria2c";
    isDesktop = false;
  };
in
selfLib.mkModule {
  name = "apps.media.downloader";
  description = "Aria2 multi-protocol high-speed CLI downloader manager and tools with pure upstream binary";

  preservation = {
    userDirectories = [ ".tdl" ];
  };

  hmConfig = {
    home.packages = [
      tdlNative
    ];

    programs.aria2 = {
      enable = true;
      package = aria2Native;
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
