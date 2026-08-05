{
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.media.video.yt-dlp";
  description = "yt-dlp CLI video downloader configuration";

  hmConfig =
    hmOpts:
    let
      homeDir = hmOpts.config.home.homeDirectory;
      username = hmOpts.config.home.username;
      zenProfile = "${homeDir}/.config/zen/${username}";
    in
    {
      programs.yt-dlp = {
        enable = true;
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
}
