{ pkgs }:

let
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
in
[
  # Utilities & Keymaps
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
    version = "2026.5.2026070801";
    hash = "sha256-ft9F6Ok/0VU3P9+AAAxW51NE5RlEK6VwtFPaMYq+GLg=";
    arch = "";
  })
  (mkExtension {
    name = "vscode-python-envs";
    publisher = "ms-python";
    version = "1.37.2026072401";
    hash = "sha256-E/DDoOQ/StQLsiAomhaCcz2hqprkPdEdJoTXdt+UrEs=";
    arch = "";
  })
  (mkExtension {
    name = "debugpy";
    publisher = "ms-python";
    version = "2026.7.12031010";
    hash = "sha256-rxfDCNyW3zQLZrzyiu04LCm9f7TiK8Q8pBxiWk8x0rY=";
    arch = "";
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
    version = "2026.7.12041005";
    hash = "sha256-O6rvFG585SKumoOL2iIPU2Qhe19upYj/mKowU+/w24E=";
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
    version = "2026.64.0";
    hash = "sha256-9bsPaHoiOqkXVf6iss5KNQlrKl8ymA0rBYl/HzxiF7M=";
    arch = "";
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
