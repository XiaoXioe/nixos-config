{
  lib,
  selfLib,
  ...
}:

let
  defaultApps = {
    text = [ "codium.desktop" ];
    image = [ "org.gnome.gThumb.desktop" ];
    audio = [ "mpv.desktop" ];
    video = [ "mpv.desktop" ];
    directory = [ "org.kde.dolphin.desktop" ];
    office = [ "org.onlyoffice.desktopeditors" ];
    pdf = [ "org.pwmt.zathura" ];
    terminal = [ "org.wezfurlong.wezterm.desktop" ];
    archive = [ "org.kde.ark.desktop" ];
    discord = [ "com.discordapp.Discord.desktop" ];
    link = [ "firefox.desktop" ];
  };
  mimeMap = {
    link = [
      "x-scheme-handler/http"
      "x-scheme-handler/https"
      "x-scheme-handler/about"
      "x-scheme-handler/unknown"
    ];
    text = [
      "text/html"
      "text/plain"
      "text/x-log"
      "text/x-csrc"
      "text/x-chdr"
      "text/x-markdown"
      "text/markdown"
      "application/json"
      "text/x-shellscript"
      "application/javascript"
      "application/vnd.apple.keynote"
      "application/x-wine-extension-mq5"
      "text/x-python"
      "text/x-python3"
      "text/x-go"
      "text/x-rust"
      "text/x-c++src"
      "text/x-c++hdr"
      "text/x-java"
      "text/css"
      "text/javascript"
      "text/typescript"
      "application/typescript"
      "text/x-yaml"
      "text/yaml"
    ];
    image = [
      "image/bmp"
      "image/gif"
      "image/jpeg"
      "image/jpg"
      "image/png"
      "image/svg+xml"
      "image/tiff"
      "image/vnd.microsoft.icon"
      "image/webp"
    ];
    audio = [
      "audio/aac"
      "audio/mpeg"
      "audio/ogg"
      "audio/opus"
      "audio/wav"
      "audio/webm"
      "audio/x-matroska"
    ];
    video = [
      "video/mp2t"
      "video/mp4"
      "video/mpeg"
      "video/ogg"
      "video/webm"
      "video/x-flv"
      "video/x-matroska"
      "video/x-msvideo"
    ];
    directory = [ "inode/directory" ];
    office = [
      "application/vnd.oasis.opendocument.text"
      "application/vnd.oasis.opendocument.spreadsheet"
      "application/vnd.oasis.opendocument.presentation"
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      "application/vnd.openxmlformats-officedocument.presentationml.presentation"
      "application/msword"
      "application/vnd.ms-excel"
      "application/vnd.ms-powerpoint"
      "application/rtf"
    ];
    pdf = [ "application/pdf" ];
    terminal = [ "terminal" ];
    archive = [
      "application/zip"
      "application/rar"
      "application/7z"
      "application/*tar"
    ];
    discord = [ "x-scheme-handler/discord" ];
  };
  associations = lib.listToAttrs (
    lib.flatten (
      lib.mapAttrsToList (
        key: mimeTypes: map (type: lib.nameValuePair type defaultApps."${key}") mimeTypes
      ) mimeMap
    )
  );
in

selfLib.mkModule {
  name = "apps.dev.mime-associations";
  description = "MIME type associations and default applications";

  hmConfig = hmOpts: {
    xdg.mimeApps = {
      enable = true;
      associations.added = associations;
      defaultApplications = associations;
    };
  };
}
