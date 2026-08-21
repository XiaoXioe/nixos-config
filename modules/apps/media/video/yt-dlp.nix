{
  config,
  pkgs,
  selfLib,
  ...
}:

let
  username = config.my.user.name;
  zenProfile = "/home/${username}/.config/zen/${username}";
in
selfLib.mkModule {
  name = "apps.media.video.yt-dlp";
  description = "yt-dlp CLI video downloader configuration via shared Arch Linux Distrobox container";

  distroboxCfg = selfLib.distrobox.arch {
    packages =
      with pkgs;
      [
        yt-dlp # → "yt-dlp", binName "yt-dlp" (auto)
        ffmpeg # → "ffmpeg"
      ]
      ++ [
        # string fallback: deps tanpa Nix equivalent yang perlu di-export
        "atomicparsley"
        "python-mutagen"
        "aria2"
      ];
    # image, distro, package, binName — semua auto dari helper
    hmProgram = {
      name = "yt-dlp";
      # binName = "yt-dlp" — sudah inherit dari top-level binName
      passWrapperAsPackage = true;
      extraConfig = {
        settings = {
          format = "'bv+ba/b'";
          merge-output-format = "mkv";
          output = "'%(title)s [%(id)s].%(ext)s'";

          cookies-from-browser = "firefox:${zenProfile}";

          embed-metadata = true;
          embed-thumbnail = true;
          embed-chapters = true;

          embed-subs = true;
          sub-langs = "en,id,-live_chat";

          concurrent-fragments = 4;
          force-ipv4 = true;
          no-mtime = true;
          sponsorblock-mark = "all";
          sponsorblock-remove = "sponsor";
        };
      };
    };
  };
}
