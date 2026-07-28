{ pkgs }:

{
  ## UI
  "workbench.colorTheme" = "Catppuccin Mocha";
  "workbench.iconTheme" = "catppuccin-mocha";
  "editor.fontFamily" = "'Adwaita Mono', 'JetBrainsMono Nerd Font', monospace";
  "editor.fontSize" = 18;
  "editor.fontLigatures" = true;
  "editor.minimap.enabled" = false;

  # Layout
  "workbench.startupEditor" = "none";
  "workbench.editor.showTabs" = "none";
  "workbench.editor.limit.enabled" = true;
  "workbench.editor.limit.value" = 10;
  "workbench.editor.limit.perEditorGroup" = true;
  "workbench.sideBar.location" = "right";
  "workbench.activityBar.location" = "hidden";
  "workbench.statusBar.visible" = false;
  "workbench.layoutControl.enabled" = false;
  "explorer.confirmDelete" = false;
  "explorer.openEditors.visible" = 0;
  "breadcrumbs.enabled" = false;
  "editor.scrollbar.verticalScrollbarSize" = 2;
  "editor.scrollbar.horizontalScrollbarSize" = 2;
  "editor.scrollbar.vertical" = "hidden";
  "editor.scrollbar.horizontal" = "hidden";

  # Window
  "window.titleBarStyle" = "custom";
  "window.menuBarVisibility" = "toggle";
  "editor.mouseWheelZoom" = true;

  # Files
  "files.autoSave" = "onWindowChange";
  "files.insertFinalNewline" = true;
  "explorer.confirmDragAndDrop" = false;
  "editor.renderControlCharacters" = false;

  # Format on save
  "editor.formatOnSave" = true;
  "editor.formatOnType" = true;
  "editor.formatOnPaste" = true;
  "editor.inlayHints.enabled" = "off";

  # Updates
  "update.mode" = "none";
  "extensions.autoUpdate" = false;
  "vsicons.dontShowNewVersionMessage" = true;

  # Nix Language Server
  "nix.serverPath" = "${pkgs.nixd}/bin/nixd";
  "nix.enableLanguageServer" = true;
  "nix.formatterPath" = "${pkgs.nixfmt}/bin/nixfmt";
  "nix.serverSettings" = {
    "nixd" = {
      "formatting" = {
        "command" = [ "${pkgs.nixfmt}/bin/nixfmt" ];
      };
    };
  };

  # Per-language formatters
  "[python]" = {
    "editor.defaultFormatter" = "ms-python.black-formatter";
    "editor.codeActionsOnSave" = {
      "source.fixAll" = "explicit";
      "source.organizeImports" = "explicit";
    };
  };
  "[shellscript]" = {
    "editor.defaultFormatter" = "foxundermoon.shell-format";
    "editor.codeActionsOnSave.source.fixAll" = "explicit";
  };
  "[fish]" = {
    "editor.defaultFormatter" = "bmalehorn.vscode-fish";
  };
  "[toml]" = {
    "editor.defaultFormatter" = "tamasfe.even-better-toml";
  };

  # SQLFluff (Dialek SQLite)
  "sqlfluff.dialect" = "sqlite";
  "sqlfluff.executablePath" = "${pkgs.sqlfluff}/bin/sqlfluff";
  "sqlfluff.format.enabled" = true;
  "sqlfluff.linter.run" = "onType";
  "sqlfluff.linter.diagnosticSeverity" = "error";
  "sqlfluff.format.arguments" = [ "--FIX-EVEN-UNPARSABLE" ];

  "[sql]" = {
    "editor.defaultFormatter" = "sqlfluff.vscode-sqlfluff";
  };

  "[php]" = {
    "editor.defaultFormatter" = "bmewburn.vscode-intelephense-client";
  };

  "intelephense.format.enable" = true;

  "[yaml]" = {
    "editor.defaultFormatter" = "esbenp.prettier-vscode";
  };
  "[javascript]" = {
    "editor.defaultFormatter" = "esbenp.prettier-vscode";
  };
  "[html]" = {
    "editor.defaultFormatter" = "esbenp.prettier-vscode";
  };
  "[json]" = {
    "editor.defaultFormatter" = "esbenp.prettier-vscode";
  };
  "[jsonc]" = {
    "editor.defaultFormatter" = "esbenp.prettier-vscode";
  };

  # MQL5
  "[mql5]" = {
    "editor.defaultFormatter" = "ngSoftware.mql-clangd";
  };

  # Error Lens
  "errorLens.delay" = 500;
  "errorLens.enabledDiagnosticLevels" = [
    "error"
    "warning"
  ];
  "errorLens.gutterIconsEnabled" = false;
  "errorLens.fontStyleItalic" = true;

  # Built-in linters
  "json.validate.enable" = true;
  "shellcheck.executablePath" = "${pkgs.shellcheck}/bin/shellcheck";
  "shellformat.path" = "${pkgs.shfmt}/bin/shfmt";
  "black-formatter.path" = [ "${pkgs.black}/bin/black" ];
  "ruff.path" = [ "${pkgs.ruff}/bin/ruff" ];

  # Disable workspace trust prompt
  "security.workspace.trust.enabled" = false;
}
