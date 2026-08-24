{
  config,
  selfLib,
  ...
}:

let
  username = config.my.user.name;
  zenProfile = "/home/${username}/.config/zen/${username}";
in
selfLib.mkModule {
  name = "apps.media.video.yt-dlp";
  description = "yt-dlp CLI video downloader configuration via Nix binary cache";

  hmConfig = {
    programs.yt-dlp = {
      enable = true;
      package = selfLib.fetchCachePinned "yt_dlp";
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
