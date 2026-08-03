{
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.media.video.gallery-dl";
  description = "gallery-dl image and video batch downloader configuration";

  hmConfig = hmOpts: {
    programs.gallery-dl = {
      enable = true;
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
          "${hmOpts.config.home.homeDirectory}/.config/zen/${hmOpts.config.home.username}"
          null
          "Akun 1"
        ];

        "cache" = {
          "file" = "~/.local/share/gallery-dl/cache.sqlite3";
        };
      };
    };
  };
}
