{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:

let
  mkExtension = { name, publisher, version, hash, arch ? "linux-x64" }:
    pkgs.vscode-utils.buildVscodeMarketplaceExtension {
      mktplcRef = { inherit name publisher version arch hash; };
    };

  marketplaceExts = [
    (mkExtension { name = "sublime-keybindings"; publisher = "ms-vscode"; version = "4.1.10"; hash = "sha256-XlogenuBmP+tE18VLH4lUSpOq/7d022n8HgXnKjY3n0="; })
    (mkExtension { name = "sqlite-viewer"; publisher = "qwtel"; version = "26.2.5"; hash = "sha256-fAhUWv2hyoh2G9EXQwKeBuMEwp+1kjBl12WM8/W/4zs="; arch = ""; })
    (mkExtension { name = "vscode-sqlfluff"; publisher = "sqlfluff"; version = "4.0.2"; hash = "sha256-Toh8jN6D08eroXPlreDy+5h8czyloUjwq4A9kFnvPdM="; arch = ""; })
    (mkExtension { name = "vscode-intelephense-client"; publisher = "bmewburn"; version = "1.18.4"; hash = "sha256-fGvQq8pGpDQc9q+uhouXNaWAHDGTl0cFla0qivhNaFQ="; arch = ""; })
    (mkExtension { name = "vscode-scheme"; publisher = "sjhuangx"; version = "0.4.0"; hash = "sha256-BN+C64YQ2hUw5QMiKvC7PHz3II5lEVVy0Shtt6t3ch8="; arch = ""; })
    (mkExtension { name = "RunOnSave"; publisher = "emeraldwalk"; version = "1.1.5"; hash = "sha256-kN7oQPeLJyK9GXxnSchKcUF4XIXQ+Yd7dsSHwT/ua6k="; arch = ""; })
  ];

  builtinExts = with pkgs.vscode-extensions; [
    ms-python.python jnoortheen.nix-ide yzhang.markdown-all-in-one
    bmalehorn.vscode-fish esbenp.prettier-vscode tamasfe.even-better-toml ms-python.black-formatter foxundermoon.shell-format
    charliermarsh.ruff timonwong.shellcheck mkhl.direnv usernamehw.errorlens christian-kohler.path-intellisense
    catppuccin.catppuccin-vsc catppuccin.catppuccin-vsc-icons mhutchie.git-graph
  ];
in
selfLib.mkModule {
  name = "apps.editors.vscodium";
  description = "Vscodium configuration";

  hmConfig = {
    home.packages = with pkgs; [ black shfmt nixfmt ruff shellcheck nixd sqlite sqlfluff php ];
    programs.vscodium = {
      enable = true;
      argvSettings = { ignore-gpu-blocklist = true; enable-crash-reporter = false; disable-gpu-compositing = false; };
      mutableExtensionsDir = false;
      profiles.default = {
        extensions = builtinExts ++ marketplaceExts;
        userSettings = {
          "workbench.colorTheme" = "Catppuccin Mocha";
          "workbench.iconTheme" = "catppuccin-mocha";
          "editor.fontFamily" = "'Adwaita Mono', 'JetBrainsMono Nerd Font', monospace";
          "editor.fontSize" = 18;
          "editor.fontLigatures" = true;
          "editor.minimap.enabled" = false;
          "workbench.startupEditor" = "none";
          "workbench.editor.showTabs" = "none";
          "workbench.sideBar.location" = "right";
          "workbench.activityBar.location" = "hidden";
          "workbench.statusBar.visible" = false;
          "window.titleBarStyle" = "custom";
          "window.menuBarVisibility" = "toggle";
          "editor.mouseWheelZoom" = true;
          "files.autoSave" = "onWindowChange";
          "files.insertFinalNewline" = true;
          "editor.formatOnSave" = true;
          "update.mode" = "none";
          "nix.serverPath" = "nixd";
          "nix.enableLanguageServer" = true;
          "[python]" = { "editor.defaultFormatter" = "ms-python.black-formatter"; "editor.codeActionsOnSave" = { "source.fixAll" = "explicit"; "source.organizeImports" = "explicit"; }; };
          "errorLens.enabledDiagnosticLevels" = [ "error" "warning" ];
        } // lib.genAttrs [ "yaml" "javascript" "html" "json" "jsonc" ] (_lang: { "editor.defaultFormatter" = "esbenp.prettier-vscode"; });
      };
    };
  };
}
