{
  pkgs,
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
    directory = [ "nemo.desktop" ];
    office = [ "onlyoffice-desktopeditors.desktop" ];
    pdf = [ "org.pwmt.zathura.desktop" ];
    terminal = [ "org.wezfurlong.wezterm.desktop" ];
    archive = [ "org.gnome.FileRoller.desktop" ];
    discord = [ "discord.desktop" ];
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
      "application/json"
      "text/x-shellscript"
      "application/javascript"
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
  name = "desktop.theme";
  description = "Custom Themes";

  hmConfig = { config, ... }: {
    home.pointerCursor = {
      name = "Vimix-white-cursors";
      package = pkgs.vimix-cursors;
      size = 24;
      gtk.enable = true;
      x11.enable = true;
    };
    gtk = {
      enable = true;
      gtk4.theme = config.gtk.theme;
      theme = {
        name = "Colloid-Dark";
        package = pkgs.colloid-gtk-theme.override {
          colorVariants = [ "dark" ];
          tweaks = [ "normal" ];
        };
      };
      iconTheme = {
        name = "Tela-circle-dark";
        package = pkgs.tela-circle-icon-theme;
      };
      font = {
        name = "Adwaita Mono";
        size = 10;
      };
    };
    xdg.mimeApps = {
      enable = true;
      associations.added = associations;
      defaultApplications = associations;
    };
    home.sessionVariables = {
      EDITOR = "codium -w";
      BROWSER = "firefox";
      QT_QPA_PLATFORM = "wayland;xcb";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    };
  };
}
