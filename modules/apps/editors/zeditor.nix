{
  pkgs,
  selfLib,
  ...
}:

let
  appInfo = selfLib.appVersions.zed;

  zedNative = (selfLib.mkNativeApp pkgs) {
    name = "zed";
    inherit (appInfo) version;
    src = selfLib.fetchApp pkgs "zed";
    execPath = "zed.app/bin/zed";
    binName = "zed";
  };
in
selfLib.mkModule {
  name = "apps.editors.zeditor";
  description = "Zed-editor configuration";

  hmConfig = {
    home.packages =
      (selfLib.fetchCachePinned [
        "black"
        "nixd"
        "sqlfluff"
      ])
      ++ (with pkgs; [
        shfmt
        nixfmt
        shellcheck
        nil
        sqlite
        php
        fish
      ]);

    programs.zed-editor = {
      enable = true;
      package = zedNative;

      # Kunci file agar menjadi symlink Nix murni (Read-Only)
      mutableUserSettings = false;
      mutableUserKeymaps = false;
      mutableUserTasks = false;

      extensions = [
        "nix"
        "html"
        "fish"
        "toml"
        "sql"
        "catppuccin"
        "catppuccin-icons"
      ];

      userSettings = {
        auto_update = false;
        base_keymap = "SublimeText";
        buffer_font_family = "Adwaita Mono";
        buffer_font_size = 18;
        ui_font_size = 16;
        buffer_font_features = {
          liga = false;
          calt = false;
        };
        telemetry = {
          diagnostics = false;
          metrics = false;
        };

        project_panel = {
          dock = "right";
          default_width = 240;
        };
        outline_panel = {
          dock = "right";
          default_width = 240;
        };
        collaboration_panel = {
          dock = "right";
        };
        git_panel = {
          dock = "right";
        };
        agent = {
          dock = "left";
          favorite_models = [ ];
          model_parameters = [ ];
        };

        tabs = {
          file_icons = true;
          git_status = true;
          show_diagnostics = "off";
        };
        minimap = {
          show = "never";
        };
        scrollbar = {
          show = "never";
        };
        toolbar = {
          breadcrumbs = false;
          quick_actions = false;
        };

        cursor_blink = false;
        reduce_motion = "on";
        hover_popover_enabled = false;
        show_edit_predictions = false;
        lsp_document_colors = "none";
        indent_guides = {
          enabled = false;
        };
        git = {
          inline_blame = {
            enabled = false;
          };
        };

        theme = {
          mode = "dark";
          light = "One Light";
          dark = "Catppuccin Mocha";
        };
        icon_theme = {
          mode = "dark";
          light = "Zed (Default)";
          dark = "Catppuccin Mocha";
        };

        autosave = "on_window_change";
        format_on_save = "on";
        remove_trailing_whitespace_on_save = true;
        ensure_final_newline_on_save = true;
        inlay_hints = {
          enabled = false;
        };
        scroll_beyond_last_line = "off";

        languages = {
          Nix = {
            format_on_save = "on";
            formatter = {
              external = {
                command = "nixfmt";
              };
            };
          };
          Python = {
            format_on_save = "on";
            formatter = {
              external = {
                command = "black";
                arguments = [ "-" ];
              };
            };
          };
          Bash = {
            format_on_save = "on";
            formatter = {
              external = {
                command = "shfmt";
                arguments = [
                  "-i"
                  "2"
                ];
              };
            };
          };
          YAML = {
            format_on_save = "on";
            formatter = {
              external = {
                command = "prettier";
                arguments = [
                  "--parser"
                  "yaml"
                ];
              };
            };
          };
          HTML = {
            format_on_save = "on";
            formatter = {
              external = {
                command = "prettier";
                arguments = [
                  "--parser"
                  "html"
                ];
              };
            };
          };
          JSON = {
            format_on_save = "on";
            formatter = {
              external = {
                command = "prettier";
                arguments = [
                  "--parser"
                  "json"
                ];
              };
            };
          };
          JSONC = {
            format_on_save = "on";
            formatter = {
              external = {
                command = "prettier";
                arguments = [
                  "--parser"
                  "jsonc"
                ];
              };
            };
          };
          TOML = {
            format_on_save = "on";
          };
          SQL = {
            format_on_save = "on";
            formatter = {
              external = {
                command = "sqlfluff";
                arguments = [
                  "fix"
                  "--dialect"
                  "sqlite"
                  "-"
                ];
              };
            };
          };
          Fish = {
            format_on_save = "on";
            formatter = {
              external = {
                command = "fish_indent";
              };
            };
          };
          PHP = {
            format_on_save = "on";
          };
        };

        lsp = {
          nixd = {
            binary = {
              path = "${selfLib.fetchCachePinned "nixd"}/bin/nixd";
            };
          };
          nil = {
            binary = {
              path = "${pkgs.nil}/bin/nil";
            };
          };
        };
      };
    };
  };
}
