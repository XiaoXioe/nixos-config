{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.terminal.utilities.yazi";
  description = "Yazi modern terminal file manager configuration via Nix binary cache";

  hmConfig = {
    programs.yazi = {
      enable = true;
      package = selfLib.fetchCachePinned "yazi";
      enableFishIntegration = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      shellWrapperName = "yy";

      extraPackages = [
        pkgs.ffmpegthumbnailer
        pkgs.p7zip
        pkgs.jq
        pkgs.poppler-utils
        pkgs.fd
        pkgs.ripgrep
        pkgs.fzf
        pkgs.zoxide
        pkgs.imagemagick
        pkgs.file
      ];

      settings = {
        mgr = {
          show_hidden = true;
          show_symlink = true;
          sort_by = "alphabetical";
          sort_sensitive = false;
          sort_reverse = false;
          sort_dir_first = true;
          linemode = "size";
          ratio = [
            1
            2
            4
          ];
        };
        preview = {
          tab_size = 2;
          max_width = 1920;
          max_height = 1080;
          image_filter = "lanczos3";
          image_quality = 70;
        };
      };

      keymap = {
        mgr = {
          prepend_keymap = [
            {
              on = [ "<C-PageUp>" ];
              run = "tab_switch -1 --relative";
              desc = "Switch to previous tab";
            }
            {
              on = [ "<C-PageDown>" ];
              run = "tab_switch 1 --relative";
              desc = "Switch to next tab";
            }
            {
              on = [ "<C-c>" ];
              run = "yank";
              desc = "Copy selected files (Dolphin style)";
            }
            {
              on = [ "<C-x>" ];
              run = "yank --cut";
              desc = "Cut selected files (Dolphin style)";
            }
            {
              on = [ "<C-v>" ];
              run = "paste";
              desc = "Paste files (Dolphin style)";
            }
            {
              on = [ "<C-a>" ];
              run = "toggle_all --state=true";
              desc = "Select all files (Dolphin style)";
            }
            {
              on = [ "<F2>" ];
              run = "rename --cursor=before_ext";
              desc = "Rename file (Dolphin style)";
            }
            {
              on = [ "<Delete>" ];
              run = "remove";
              desc = "Move file to trash (Dolphin style)";
            }
          ];
        };
      };
    };
  };
}
