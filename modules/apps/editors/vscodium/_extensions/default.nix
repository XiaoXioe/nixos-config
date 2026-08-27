{ pkgs }:

let
  mkExtension =
    {
      name,
      publisher,
      version,
      hash,
      arch ? "",
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
in
[
  # Utilities & Keymaps
  (mkExtension {
    name = "sublime-keybindings";
    publisher = "ms-vscode";
    version = "4.1.10";
    hash = "sha256-XlogenuBmP+tE18VLH4lUSpOq/7d022n8HgXnKjY3n0=";
    arch = "";
  })
  (mkExtension {
    name = "sqlite-viewer";
    publisher = "qwtel";
    version = "26.8.2";
    hash = "sha256-8B3h45lK4irs4Y0Kk+g4w+KsGxIyXSwWiLlAm6ed5bY=";
    arch = "linux-x64";
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
    version = "1.18.5";
    hash = "sha256-yLp7lBWjdH+KtBUlkjLWz5OmAvEQWJFIVCVsBt9BTeE=";
    arch = "";
  })
  (mkExtension {
    name = "RunOnSave";
    publisher = "emeraldwalk";
    version = "1.1.5";
    hash = "sha256-kN7oQPeLJyK9GXxnSchKcUF4XIXQ+Yd7dsSHwT/ua6k=";
    arch = "";
  })
  (mkExtension {
    name = "mql-clangd";
    publisher = "ngSoftware";
    version = "1.1.63";
    hash = "sha256-mZMj7t8yZH8CYrsqX8mM6S/fNWadghYxLURsnYLUmLo=";
    arch = "";
  })

  # Languages
  (mkExtension {
    name = "python";
    publisher = "ms-python";
    version = "2026.7.2026082601";
    hash = "sha256-JAQbRaOx6bJLv66uZWs4Pa00y3V9gOV5sX4zYZoThrw=";
    arch = "linux-x64";
  })
  (mkExtension {
    name = "debugpy";
    publisher = "ms-python";
    version = "2026.7.12371009";
    hash = "sha256-fXX8DpfkdCufLPhxKpsdj3dH5U/PUSIgvzexyUe5oQ0=";
    arch = "linux-x64";
  })
  (mkExtension {
    name = "nix-ide";
    publisher = "jnoortheen";
    version = "0.5.13";
    hash = "sha256-0pMMnYFX+Ghs42Tvfcv9QqwhrEhCjIa7+6xJ51Fa0Dk=";
    arch = "";
  })
  (mkExtension {
    name = "markdown-all-in-one";
    publisher = "yzhang";
    version = "3.6.3";
    hash = "sha256-xJhbFQSX1DDDp8iE/R8ep+1t5IRusBkvjHcNmvjrboM=";
    arch = "";
  })
  (mkExtension {
    name = "vscode-clangd";
    publisher = "llvm-vs-code-extensions";
    version = "0.6.0";
    hash = "sha256-hmoAPCp0BKB3z6z2Ai0w45RDE9v3BYupmu2A5y5OM50=";
    arch = "";
  })

  # Formatters
  (mkExtension {
    name = "vscode-fish";
    publisher = "bmalehorn";
    version = "1.0.49";
    hash = "sha256-oG0KOvQZ2E5FroXaUT6lGw1zDSQ/bisHLMMkygbGqQE=";
    arch = "";
  })
  (mkExtension {
    name = "prettier-vscode";
    publisher = "esbenp";
    version = "12.4.0";
    hash = "sha256-RtIqVns16+W9/9coBFd0LNZ+ZdfhslC7d1qyvoZHmkI=";
    arch = "";
  })
  (mkExtension {
    name = "even-better-toml";
    publisher = "tamasfe";
    version = "0.21.2";
    hash = "sha256-IbjWavQoXu4x4hpEkvkhqzbf/NhZpn8RFdKTAnRlCAg=";
    arch = "";
  })
  (mkExtension {
    name = "black-formatter";
    publisher = "ms-python";
    version = "2026.7.12371004";
    hash = "sha256-gxWLSZyy1tal3aPFEWMhRIGJeia21Dinuv7mcZ8Dviw=";
    arch = "";
  })
  (mkExtension {
    name = "shell-format";
    publisher = "foxundermoon";
    version = "7.2.8";
    hash = "sha256-Z3vmRzqPCxkQbn39I54bh/ND+0HcE9iFUhKQ29GRd7o=";
    arch = "";
  })

  # Linters
  (mkExtension {
    name = "ruff";
    publisher = "charliermarsh";
    version = "2026.74.0";
    hash = "sha256-19D0nudX3NWF8dtkfkbXctb/BtPr4VuIVGXLBcg9JzQ=";
    arch = "linux-x64";
  })
  (mkExtension {
    name = "shellcheck";
    publisher = "timonwong";
    version = "0.39.5";
    hash = "sha256-8f9LGmNE8ilPYZmbJpmmAx9DkKJXbQzAia11rM3wTec=";
    arch = "";
  })

  # Productivity
  (mkExtension {
    name = "errorlens";
    publisher = "usernamehw";
    version = "3.28.0";
    hash = "sha256-7eu7y9IR1uxSFZ0IplDieFt3iWbcmdwf1lAcXq+S4C8=";
    arch = "";
  })
  (mkExtension {
    name = "path-intellisense";
    publisher = "christian-kohler";
    version = "2.10.0";
    hash = "sha256-bE32VmzZBsAqgSxdQAK9OoTcTgutGEtgvw6+RaieqRs=";
    arch = "";
  })

  # Theme & Icons
  (mkExtension {
    name = "catppuccin-vsc";
    publisher = "catppuccin";
    version = "3.19.0";
    hash = "sha256-6/NHZkg37b6RyZIP89FMltSii+7sC5UTfHYFgyYyl4A=";
    arch = "";
  })
  (mkExtension {
    name = "catppuccin-vsc-icons";
    publisher = "catppuccin";
    version = "1.26.0";
    hash = "sha256-V1ZhNtCouo0EDrblvoZsiMy7BPPSGdOn5SoZl4kA/z0=";
    arch = "";
  })

  # Git
  (mkExtension {
    name = "git-graph";
    publisher = "mhutchie";
    version = "1.30.0";
    hash = "sha256-sHeaMMr5hmQ0kAFZxxMiRk6f0mfjkg2XMnA4Gf+DHwA=";
    arch = "";
  })
]
