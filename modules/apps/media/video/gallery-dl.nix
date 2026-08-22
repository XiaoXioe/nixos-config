{
  config,
  pkgs,
  selfLib,
  ...
}:

let
  appInfo = selfLib.appVersions.gallery-dl;

  gallerydlNative = (selfLib.mkNativeApp pkgs) {
    name = "gallery-dl";
    inherit (appInfo) version;
    src = selfLib.fetchApp pkgs "gallery-dl";
    execPath = "bin/gallery-dl.bin";
    binName = "gallery-dl";
    isDesktop = false;
    extraPkgs = [ pkgs.ffmpeg ];
  };
in
selfLib.mkModule {
  name = "apps.media.video.gallery-dl";
  description = "gallery-dl image and video batch downloader configuration with pure upstream binary";

  hmConfig = {
    programs.gallery-dl = {
      enable = true;
      package = gallerydlNative;
      settings = {
        "extractor" = {
          "base-directory" = "~/CloudStorage/gdrive-akbar-68-decrypted/Gallery/";
          "archive" = "~/.local/share/gallery-dl/archive.sqlite3";

          "directory" = [
            "{category}"
            "{user[name]|username|id}"
          ];

          "facebook" = {
            "directory" = [
              "facebook"
              "{username|author|group|group_id|id}"
            ];
          };

          "pixiv" = {
            "ugoira" = "original";
            "postprocessors" = [
              {
                "name" = "ugoira";
                "extension" = "mp4";
                "ffmpeg-location" = "ffmpeg";
              }
              { "name" = "mtime"; }
            ];
          };
        };

        "cookies" = [
          "zen"
          "/home/${config.my.user.name}/.config/zen/${config.my.user.name}"
          null
          "Account 01"
        ];

        "cache" = {
          "file" = "~/.local/share/gallery-dl/cache.sqlite3";
        };
      };
    };
  };
}
