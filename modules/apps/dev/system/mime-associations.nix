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
        zen = "app.zen_browser.zen.desktop";
        firefox = "firefox.desktop";
        brave = "brave-browser.desktop";
        chromium = "chromium-browser.desktop";
        librewolf = "librewolf.desktop";
      };
      editorDesktopMap = {
        codium = "codium.desktop";
        vscodium = "codium.desktop";
        neovim = "nvim.desktop";
        zeditor = "dev.zed.Zed.desktop";
      };
      fileManagerDesktopMap = {
        dolphin = "org.kde.dolphin.desktop";
        nemo = "nemo.desktop";
      };

      activeBrowsersList = lib.concatLists [
        (lib.optional (osConfig.my.apps.browsers.zen.enable or false) "app.zen_browser.zen.desktop")
        (lib.optional (osConfig.my.apps.browsers.chromium.enable or false) "chromium-browser.desktop")
        (lib.optional (osConfig.my.apps.browsers.brave.enable or false) "brave-browser.desktop")
        (lib.optional (osConfig.my.apps.browsers.firefox.enable or false) "firefox.desktop")
        (lib.optional (osConfig.my.apps.browsers.librewolf.enable or false) "librewolf.desktop")
      ];

      preferredBrowser =
        browserDesktopMap.${osConfig.my.defaultApps.browser}
          or "${osConfig.my.defaultApps.browser}.desktop";

      browserOrder = lib.unique ([ preferredBrowser ] ++ activeBrowsersList);

      defaultApps = {
        text = [
          (editorDesktopMap.${osConfig.my.defaultApps.editor} or "${osConfig.my.defaultApps.editor}.desktop")
        ];
        image = lib.optional (osConfig.my.apps.media.gthumb.enable or false) "org.gnome.gThumb.desktop";
        audio = lib.optional (osConfig.my.apps.media.video.mpv.enable or false) "mpv.desktop";
        video = lib.optional (osConfig.my.apps.media.video.mpv.enable or false) "mpv.desktop";
        directory = [
          (fileManagerDesktopMap.${osConfig.my.defaultApps.fileManager}
            or "${osConfig.my.defaultApps.fileManager}.desktop"
          )
        ];
        office = lib.optional (osConfig.my.apps.office.onlyoffice.enable or false
        ) "org.onlyoffice.desktopeditors.desktop";
        pdf =
          if (osConfig.my.apps.office.zathura.enable or false) then
            [ "org.pwmt.zathura.desktop" ]
          else
            lib.take 1 activeBrowsersList;
        terminal = [ terminalDesktop ];
        archive = [ "org.kde.ark.desktop" ];
        discord = lib.optional (osConfig.my.apps.social.discord.enable or false
        ) "com.discordapp.Discord.desktop";
        link = browserOrder;
      };

      filteredDefaultApps = lib.filterAttrs (_: apps: apps != [ ]) defaultApps;

      associations = lib.listToAttrs (
        lib.flatten (
          lib.mapAttrsToList (
            key: mimeTypes:
            if filteredDefaultApps ? ${key} then
              map (type: lib.nameValuePair type filteredDefaultApps.${key}) mimeTypes
            else
              [ ]
          ) mimeMap
        )
      );
    in
    {
      xdg.configFile."mimeapps.list".force = true;

      xdg.mimeApps = {
        enable = true;
        associations.added = associations;
        defaultApplications = associations;
      };
    };
}
