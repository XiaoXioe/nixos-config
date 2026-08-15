{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.dev.system.file-manager.nemo";
  description = "Nemo Cinnamon file manager settings and packages";

  hmConfig =
    hmOpts:
    let
      inherit (hmOpts) lib;
    in
    {
      home.packages = with pkgs; [
        nemo-with-extensions
        nemo-fileroller
      ];

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
