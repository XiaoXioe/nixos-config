{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.my.user.apps.editors.zeditor;
in
{
  options.my.user.apps.editors.zeditor = {
    enable = lib.mkEnableOption "Zed-editor configuration";
  };

  config = lib.mkIf cfg.enable {
    programs.zed-editor = {
      enable = true;
      package = pkgs.zed-editor-fhs;

      # Kunci file agar menjadi symlink Nix murni (Read-Only)
      mutableUserSettings = false;
      mutableUserKeymaps = false;
      mutableUserTasks = false;

      # Mengganti ekstensi ayu dengan catppuccin
      extensions = [
        "nix"
        "bash"
        "yaml"
        "html"
        "fish"
        "python"
        "catppuccin"
        "macos-classic"
        "catppuccin-icons"
      ];

      # Menggunakan Nix attribute set yang akan dikonversi ke JSON
      userSettings = {
        auto_update = false;
        buffer_font_family = "Adwaita Mono";
        project_panel = {
          dock = "left";
        };
        outline_panel = {
          dock = "left";
        };
        collaboration_panel = {
          dock = "left";
        };
        agent = {
          dock = "right";
          favorite_models = [ ];
          model_parameters = [ ];
        };
        git_panel = {
          dock = "left";
        };
        telemetry = {
          diagnostics = false;
          metrics = false;
        };
        base_keymap = "SublimeText";
        ui_font_size = 16;
        buffer_font_size = 15;

        # Konfigurasi Tema
        theme = {
          mode = "dark";
          light = "One Light";
          dark = "macOS Classic Dark";
        };
        icon_theme = {
          mode = "dark";
          light = "Zed (Default)";
          dark = "Catppuccin Latte";
        };

        # Konfigurasi Formatter per bahasa
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
          Fish = {
            format_on_save = "on";
            formatter = {
              external = {
                # fish_indent otomatis membaca dari stdin dan menulis ke stdout
                command = "fish_indent";
              };
            };
          };
        };
      };
    };
  };
}
