{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.media.downloader";
  description = "Aria2 multi-protocol high-speed CLI downloader manager via shared Arch Linux Distrobox container";

  preservation = {
    userDirectories = [ ".tdl" ];
  };

  distroboxCfg = selfLib.distrobox.arch {
    packages = with pkgs; [ aria2 ];
    # image = "docker.io/library/archlinux:latest" — auto dari helper
    # distro = "arch" — auto dari helper
    # binName = "aria2c" — auto dari pkgs.aria2.meta.mainProgram
    # package = pkgs.aria2 — auto dari packages list (native fallback)
    hmProgram = {
      name = "aria2";
      # binName = "aria2c" — sudah inherit dari top-level binName
      passWrapperAsPackage = true;
      extraConfig = {
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
  };

  hmConfig = {
    home.packages = with pkgs; [
      tdl
    ];
  };
}
