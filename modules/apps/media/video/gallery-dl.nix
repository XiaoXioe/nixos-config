{
  config,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.media.video.gallery-dl";
  description = "gallery-dl image and video batch downloader configuration via Nix binary cache";

  hmConfig = {
    programs.gallery-dl = {
      enable = true;
      package = selfLib.fetchCachePinned "gallery_dl";
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
