{
  lib,
  pkgs,
  userName,
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
  name = "apps.dev.file-manager";
  description = "FileManager user settings";

  hmConfig =
    hmOpts:
    let
      lib = hmOpts.lib;
    in
    {
      xdg = {
        portal = {
          enable = true;
          extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
          config.common.default = "*";
        };

        configFile."baloofilerc".text = ''
          [Basic Settings]
          Indexing-Enabled=false
        '';

        configFile."menus/applications.menu".text = ''
          <!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN" "http://www.freedesktop.org/standards/menu-spec/1.0/menu.dtd">
          <Menu>
            <Name>Applications</Name>
            <DefaultAppDirs/>
            <DefaultDirectoryDirs/>
            <DefaultMergeDirs/>
          </Menu>
        '';

        configFile."dolphinrc".text = ''
          [DetailsMode]
          PreviewSize=22

          [General]
          GlobalViewProps=true
          Version=202

          [KFileDialog Settings]
          Places Icons Auto-resize=false
          Places Icons Static Size=22

          [MainWindow]
          MenuBar=Disabled
        '';

        mimeApps = {
          enable = true;
          associations.added = associations;
          defaultApplications = associations;
        };
      };

      home = {
        activation.updateKdeCache = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run env XDG_DATA_DIRS="/run/current-system/sw/share:/etc/profiles/per-user/${userName}/share:$XDG_DATA_DIRS" ${pkgs.kdePackages.kservice}/bin/kbuildsycoca6 --noincremental
        '';
        sessionVariables = {
          XDG_DATA_DIRS = "/run/current-system/sw/share:/etc/profiles/per-user/${userName}/share:$XDG_DATA_DIRS";
          QT_STYLE_OVERRIDE = "breeze";
          XCURSOR_THEME = "breeze_cursors";
        };

        packages = with pkgs; [
          kdePackages.dolphin
          kdePackages.kio
          kdePackages.kio-extras
          kdePackages.kservice
          kdePackages.breeze-icons
          kdePackages.qqc2-desktop-style
          kdePackages.ark

          zip
          unzip
          # rar
          unrar
          p7zip

          # nemo-with-extensions
          # nemo-fileroller
        ];
      };

      dconf.settings = {
        "org/nemo/preferences" = {
          always-use-browser = true;
          close-device-view-on-device-eject = true;
          date-font-choice = "auto-mono";
          date-format = "iso";
          last-server-connect-method = 3;
          default-folder-viewer = "list-view";
          inherit-folder-viewer = true;
          quick-renames-with-pause-in-between = true;
          show-edit-icon-toolbar = false;
          show-full-path-titles = false;
          show-hidden-files = true;
          show-home-icon-toolbar = true;
          show-new-folder-icon-toolbar = true;
          show-open-in-terminal-toolbar = false;
          show-search-icon-toolbar = false;
          show-show-thumbnails-toolbar = false;
          thumbnail-limit = lib.gvariant.mkUint64 (100 * 1024 * 1024);
        };
        "org/nemo/list-view" = {
          default-zoom-level = "smaller";
          enable-folder-expansion = true;
        };
        "org/nemo/preferences/menu-config" = {
          background-menu-open-as-root = false;
          selection-menu-open-as-root = false;
          selection-menu-open-in-terminal = false;
          selection-menu-scripts = false;
        };
        "org/nemo/search" = {
          search-reverse-sort = false;
          search-sort-column = "name";
        };
        "org/nemo/window-state" = {
          maximized = true;
          network-expanded = true;
          side-pane-view = "places";
          sidebar-bookmark-breakpoint = 2;
          sidebar-width = lib.gvariant.mkInt32 180;
          start-with-sidebar = true;
        };
      };
    };
}
