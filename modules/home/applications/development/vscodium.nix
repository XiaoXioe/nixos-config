{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.my.user.vscodium;

  ms-vscode.sublime-keybindings = pkgs.vscode-utils.buildVscodeMarketplaceExtension {
    mktplcRef = {
      name = "sublime-keybindings";
      publisher = "ms-vscode";
      version = "4.1.10";
      hash = "sha256-XlogenuBmP+tE18VLH4lUSpOq/7d022n8HgXnKjY3n0=";
    };
  };
in
{
  options.my.user.vscodium = {
    enable = lib.mkEnableOption "Vscodium configuration";
  };

  config = lib.mkIf cfg.enable {
    programs.vscodium = {
      enable = true;
      profiles.default = {
        extensions = with pkgs.vscode-extensions; [
          ## Languages
          jnoortheen.nix-ide
          arrterian.nix-env-selector
          ziglang.vscode-zig
          yzhang.markdown-all-in-one
          ms-python.python

          ## Formatters
          ms-python.black-formatter
          foxundermoon.shell-format
          redhat.vscode-yaml
          tamasfe.even-better-toml
          bmalehorn.vscode-fish
          esbenp.prettier-vscode

          ## Linters
          # astral-sh.ruff # Linter Python
          charliermarsh.ruff
          timonwong.shellcheck # Linter Bash

          ## Theme
          catppuccin.catppuccin-vsc

          ## Keymaps
          ms-vscode.sublime-keybindings
        ];
        userSettings = {
          ## Tema & Font
          "workbench.colorTheme" = "Catppuccin Mocha";
          "editor.fontFamily" = "'Adwaita Mono', 'JetBrainsMono Nerd Font', monospace";

          "update.mode" = "none";
          "extensions.autoUpdate" = false;
          "window.titleBarStyle" = "custom";

          "window.menuBarVisibility" = "toggle";
          "editor.fontSize" = 18;
          # "editor.rulers" = [ 100 ];
          "vsicons.dontShowNewVersionMessage" = true;
          "explorer.confirmDragAndDrop" = false;
          "editor.fontLigatures" = true;
          "editor.minimap.enabled" = false;
          "workbench.startupEditor" = "none";

          "editor.formatOnSave" = true;
          "editor.formatOnType" = true;
          "editor.formatOnPaste" = true;
          "editor.inlayHints.enabled" = "off";

          "workbench.layoutControl.type" = "menu";
          "workbench.editor.limit.enabled" = true;
          "workbench.editor.limit.value" = 10;
          "workbench.editor.limit.perEditorGroup" = true;
          "workbench.editor.showTabs" = "none";
          "files.autoSave" = "onWindowChange";
          "files.insertFinalNewline" = true;
          "explorer.openEditors.visible" = 0;
          "breadcrumbs.enabled" = false;
          "editor.renderControlCharacters" = false;
          "workbench.activityBar.location" = "hidden";
          "workbench.statusBar.visible" = false;
          "editor.scrollbar.verticalScrollbarSize" = 2;
          "editor.scrollbar.horizontalScrollbarSize" = 2;
          "editor.scrollbar.vertical" = "hidden";
          "editor.scrollbar.horizontal" = "hidden";
          "workbench.layoutControl.enabled" = false;
          "workbench.sideBar.location" = "right";

          ## Red Hat Telemetry
          "redhat.telemetry.enabled" = false;

          "editor.mouseWheelZoom" = true;

          ## C/C++
          "clangd.arguments" = [
            "--clang-tidy"
            "--inlay-hints=false"
          ];

          ## Zig
          "zig.path" = "zig";
          "zig.zls.path" = "zls";
          "zig.zls.enabled" = "on";
          "zig.zls.warnStyle" = true;
          "zig.buildOnSaveProvider" = "zls";

          ## Nix
          "nix.serverPath" = "nixd";
          "nix.enableLanguageServer" = true;
          "nix.serverSettings" = {
            "nixd" = {
              "formatting" = {
                "command" = [ "nixfmt" ];
              };
            };
          };

          ## Default Formatters per Bahasa
          "[python]" = {
            "editor.defaultFormatter" = "ms-python.black-formatter";
            "editor.codeActionsOnSave" = {
              "source.fixAll" = "explicit";
              "source.organizeImports" = "explicit";
            };
          };
          "[shellscript]" = {
            "editor.defaultFormatter" = "foxundermoon.shell-format";
            "editor.codeActionsOnSave" = {
              "source.fixAll" = "explicit";
            };
          };
          "[yaml]" = {
            "editor.defaultFormatter" = "redhat.vscode-yaml";
          };
          "[toml]" = {
            "editor.defaultFormatter" = "tamasfe.even-better-toml";
          };
          "[fish]" = {
            "editor.defaultFormatter" = "bmalehorn.vscode-fish";
          };
          "[ini]" = {
            "editor.defaultFormatter" = "esbenp.prettier-vscode";
          };

          # Default Formatters untuk JSON
          "[json]" = {
            "editor.defaultFormatter" = "esbenp.prettier-vscode";
          };
          "[jsonc]" = {
            "editor.defaultFormatter" = "esbenp.prettier-vscode";
          };

          ## Memastikan Linter Bawaan JSON Aktif
          "json.validate.enable" = true;
          "shellcheck.executablePath" = "shellcheck";
        };
      };
    };
  };
}
