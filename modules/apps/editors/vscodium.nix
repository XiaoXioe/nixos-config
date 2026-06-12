{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.my.user.apps.editors.vscodium;

  # Helper: build marketplace extension with common args
  mkExtension =
    {
      name,
      publisher,
      version,
      hash,
      arch ? "linux-x64",
    }:
    pkgs.vscode-utils.buildVscodeMarketplaceExtension {
      mktplcRef = {
        inherit
          name
          publisher
          version
          arch
          hash
          ;
      };
    };

  # Helper: patch extension for NixOS (autoPatchelf)
  # mkPatchedExtension =
  #   ext:
  #   ext.overrideAttrs (old: {
  #     nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.autoPatchelfHook ];

  #     buildInputs = (old.buildInputs or [ ]) ++ [
  #       pkgs.stdenv.cc.cc.lib
  #       pkgs.alsa-lib
  #     ];
  #   });

  # Marketplace extensions
  marketplaceExts = [
    # AI
    # (mkExtension {
    #   name = "chatgpt";
    #   publisher = "openai";
    #   version = "26.5602.40724";
    #   hash = "sha256-meGtMspO1bDHNJRPLmlrczdyZsZ+wf36ZLi17SGf0U8=";
    # })
    # mkPatchedExtension (mkExtension {
    #   name = "continue";
    #   publisher = "Continue";
    #   version = "1.3.38";
    #   hash = "sha256-8jvllwe1iCZnF+3UGppEOk2QKdyhVSFDxthfTLIIQYQ=";
    # })

    # Languages
    (mkExtension {
      name = "sublime-keybindings";
      publisher = "ms-vscode";
      version = "4.1.10";
      hash = "sha256-XlogenuBmP+tE18VLH4lUSpOq/7d022n8HgXnKjY3n0=";
    })
    (mkExtension {
      name = "sqlite-viewer";
      publisher = "qwtel";
      version = "26.2.5";
      hash = "sha256-fAhUWv2hyoh2G9EXQwKeBuMEwp+1kjBl12WM8/W/4zs=";
      arch = "";
    })
    (mkExtension {
      name = "vscode-sqlfluff";
      publisher = "sqlfluff";
      version = "4.0.2";
      hash = "sha256-Toh8jN6D08eroXPlreDy+5h8czyloUjwq4A9kFnvPdM=";
      arch = "";
    })
    (mkExtension {
      name = "vscode-intelephense-client";
      publisher = "bmewburn";
      version = "1.18.4";
      hash = "sha256-fGvQq8pGpDQc9q+uhouXNaWAHDGTl0cFla0qivhNaFQ=";
      arch = "";
    })

    # --- TAMBAHAN UNTUK GUIX / SCHEME ---
    (mkExtension {
      name = "vscode-scheme";
      publisher = "sjhuangx";
      version = "0.4.0";
      hash = "sha256-BN+C64YQ2hUw5QMiKvC7PHz3II5lEVVy0Shtt6t3ch8=";
      arch = "";
    })
    (mkExtension {
      name = "RunOnSave";
      publisher = "emeraldwalk";
      version = "1.1.5";
      hash = "sha256-kN7oQPeLJyK9GXxnSchKcUF4XIXQ+Yd7dsSHwT/ua6k=";
      arch = "";
    })
  ];

  # nixpkgs-provided extensions (from pkgs.vscode-extensions)
  builtinExts = with pkgs.vscode-extensions; [
    # Languages
    ms-python.python
    jnoortheen.nix-ide
    yzhang.markdown-all-in-one

    # Formatters
    bmalehorn.vscode-fish
    esbenp.prettier-vscode
    tamasfe.even-better-toml
    ms-python.black-formatter
    foxundermoon.shell-format

    # Linters
    charliermarsh.ruff
    timonwong.shellcheck

    # Productivity
    mkhl.direnv
    usernamehw.errorlens
    christian-kohler.path-intellisense

    # Theme & Icons
    catppuccin.catppuccin-vsc
    catppuccin.catppuccin-vsc-icons

    # Git
    mhutchie.git-graph
  ];

in
{
  options.my.user.apps.editors.vscodium = {
    enable = lib.mkEnableOption "Vscodium configuration";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      # Formatters
      black
      shfmt
      nixfmt

      # Linters
      ruff
      shellcheck
      nixd

      # Utilities
      sqlite

      # --- TAMBAHAN PAKET BINARY UNTUK SQLITE & PHP ---
      sqlfluff # Linter & Formatter untuk SQL/SQLite
      php # Menyediakan interpreter PHP untuk linting bawaan (php -l)

      # Guix menggunakan systemd-service
    ];

    programs.vscodium = {
      enable = true;
      argvSettings = {
        ignore-gpu-blocklist = true;
        enable-crash-reporter = false;
        disable-gpu-compositing = false;
      };
      mutableExtensionsDir = false;
      profiles.default = {
        extensions = builtinExts ++ marketplaceExts;
        userSettings = {
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

          # --- (GUIX STYLE) ---
          "emeraldwalk.runonsave" = {
            "commands" = [
              {
                "match" = "\\.scm$";
                "isAsync" = true;
                "cmd" = "guix style -f \${file}";
              }
            ];
          };

          # Nix
          "nix.serverPath" = "nixd";
          "nix.enableLanguageServer" = true;
          "nix.serverSettings.nixd.formatting.command" = [ "nixfmt" ];

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

          # --- TAMBAHAN KONFIGURASI SQLFLUFF & PHP ---

          # Konfigurasi SQLFluff (Dialek SQLite)
          "sqlfluff.dialect" = "mysql";
          "sqlfluff.executablePath" = "sqlfluff";
          "sqlfluff.format.enabled" = true;
          "sqlfluff.linter.run" = "onType";
          "sqlfluff.linter.diagnosticSeverity" = "error";
          "sqlfluff.format.arguments" = [ "--FIX-EVEN-UNPARSABLE" ];

          # Tentukan Formatter Default per Bahasa
          "[sql]" = {
            "editor.defaultFormatter" = "sqlfluff.vscode-sqlfluff";
          };

          "[php]" = {
            "editor.defaultFormatter" = "bmewburn.vscode-intelephense-client";
          };

          "intelephense.format.enable" = true;
        }
        //
          lib.genAttrs
            [
              "yaml"
              "javascript"
              "html"
              "json"
              "jsonc"
            ]
            (_lang: {
              "editor.defaultFormatter" = "esbenp.prettier-vscode";
            })
        // {
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
          "shellcheck.executablePath" = "shellcheck";
        };
      };
    };
  };
}
