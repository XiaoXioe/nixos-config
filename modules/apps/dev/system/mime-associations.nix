{
  lib,
  selfLib,
  ...
}:

let
  mimeMap = {
    link = [
      "text/html"
      "application/xhtml+xml"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
      "x-scheme-handler/about"
      "x-scheme-handler/unknown"
    ];
    text = [
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
    terminal = [ "x-scheme-handler/terminal" ];
    archive = [
      "application/zip"
      "application/rar"
      "application/x-7z-compressed"
      "application/x-tar"
      "application/x-compressed-tar"
    ];
    discord = [ "x-scheme-handler/discord" ];
  };
in

selfLib.mkModule {
  name = "apps.dev.system.mime-associations";
  description = "MIME type associations and default applications";

  hmConfig =
    { osConfig, ... }:
    let
      terminalDesktopMap = {
        foot = "foot.desktop";
        alacritty = "Alacritty.desktop";
        wezterm = "org.wezfurlong.wezterm.desktop";
        kitty = "kitty.desktop";
      };
      terminalDesktop =
        terminalDesktopMap.${osConfig.my.defaultTerminal} or "${osConfig.my.defaultTerminal}.desktop";

      browserDesktopMap = {
        zen-beta = "app.zen_browser.zen.desktop";
        firefox = "org.mozilla.firefox.desktop";
        brave =
          if (osConfig.my.apps.browsers.brave.flatpak.enable or false) then
            "com.brave.Browser.desktop"
          else
            "brave-browser.desktop";
      };
      editorDesktopMap = {
        codium =
          if (osConfig.my.apps.editors.vscodium.flatpak.enable or false) then
            "com.vscodium.codium.desktop"
          else
            "codium.desktop";
        vscodium =
          if (osConfig.my.apps.editors.vscodium.flatpak.enable or false) then
            "com.vscodium.codium.desktop"
          else
            "codium.desktop";
      };
      fileManagerDesktopMap = {
        dolphin = "org.kde.dolphin.desktop";
        nemo = "nemo.desktop";
      };

      defaultApps = {
        text = [
          (editorDesktopMap.${osConfig.my.defaultApps.editor} or "${osConfig.my.defaultApps.editor}.desktop")
        ];
        image = [ "org.gnome.gThumb.desktop" ];
        audio = [ "mpv.desktop" ];
        video = [ "mpv.desktop" ];
        directory = [
          (fileManagerDesktopMap.${osConfig.my.defaultApps.fileManager}
            or "${osConfig.my.defaultApps.fileManager}.desktop"
          )
        ];
        office = [ "org.onlyoffice.desktopeditors.desktop" ];
        pdf = [ "org.pwmt.zathura.desktop" ];
        terminal = [ terminalDesktop ];
        archive = [ "org.kde.ark.desktop" ];
        discord = [ "com.discordapp.Discord.desktop" ];
        link = [
          (browserDesktopMap.${osConfig.my.defaultApps.browser}
            or "${osConfig.my.defaultApps.browser}.desktop"
          )
          "org.mozilla.firefox.desktop"
        ];
      };

      associations = lib.listToAttrs (
        lib.flatten (
          lib.mapAttrsToList (
            key: mimeTypes: map (type: lib.nameValuePair type defaultApps."${key}") mimeTypes
          ) mimeMap
        )
      );
    in
    {
      xdg.mimeApps = {
        enable = true;
        associations.added = associations;
        defaultApplications = associations;
      };
    };
}
