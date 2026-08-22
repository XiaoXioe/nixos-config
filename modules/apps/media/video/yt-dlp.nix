{
  config,
  pkgs,
  selfLib,
  ...
}:

let
  username = config.my.user.name;
  zenProfile = "/home/${username}/.config/zen/${username}";
  appInfo = selfLib.appVersions.yt-dlp;

  ytdlpNative = (selfLib.mkNativeApp pkgs) {
    name = "yt-dlp";
    inherit (appInfo) version;
    src = selfLib.fetchApp pkgs "yt-dlp";
    execPath = "bin/yt-dlp_linux";
    binName = "yt-dlp";
    isDesktop = false;
    extraPkgs = with pkgs; [
      ffmpeg
      atomicparsley
      aria2
    ];
  };
in
selfLib.mkModule {
  name = "apps.media.video.yt-dlp";
  description = "yt-dlp CLI video downloader configuration with pure upstream binary";

  hmConfig = {
    programs.yt-dlp = {
      enable = true;
      package = ytdlpNative;
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
