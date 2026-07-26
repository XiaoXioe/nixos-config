{
  lib,
  pkgs,
  userName,
  selfLib,
  ...
}:

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
      };

      home = {
        activation.updateKdeCache = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run env XDG_DATA_DIRS="/run/current-system/sw/share:/etc/profiles/per-user/${userName}/share:$XDG_DATA_DIRS" ${pkgs.kdePackages.kservice}/bin/kbuildsycoca6 --noincremental
        '';
        sessionVariables = {
          XDG_DATA_DIRS = "/run/current-system/sw/share:/etc/profiles/per-user/${userName}/share:$XDG_DATA_DIRS";
          XCURSOR_THEME = "breeze_cursors";
        };

        packages = with pkgs; [
          kdePackages.dolphin
          kdePackages.kio
          kdePackages.kio-extras
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
