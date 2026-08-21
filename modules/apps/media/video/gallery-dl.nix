{
  config,
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.media.video.gallery-dl";
  description = "gallery-dl image and video batch downloader via shared Arch Linux Distrobox container";

  distroboxCfg = selfLib.distrobox.arch {
    packages = [ "ffmpeg" ]; # string: tidak perlu native fallback untuk ffmpeg di sini
    aur = [ "gallery-dl-bin" ]; # AUR string: nama AUR berbeda dari Nix pname
    package = pkgs.gallery-dl; # explicit native fallback; binName "gallery-dl" auto dari sini
    # image, distro — auto dari helper
    # binName = "gallery-dl" — auto dari pkgs.gallery-dl.meta.mainProgram
    hmProgram = {
      name = "gallery-dl";
      extraConfig = {
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
  };
}
