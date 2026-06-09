# Per-user home-manager configuration.
# Maps nested userFeatures from lib/users.nix → my.user.* enable toggles.
{
  lib,
  userName,
  userFeatures,
  ...
}:
let
  uf = userFeatures;
in
{
  home.username = userName;
  home.homeDirectory = "/home/${userName}";

  # --- User Module Toggles ---
  my.user = {
    # Desktop (nested: my.user.desktop.*)
    desktop = {
      dms = {
        enable = uf.desktop.dms or false;
      };
      themes = {
        enable = uf.desktop.themes or false;
      };
    };

    # Settings (nested: my.user.settings.settings)
    settings = {
      settings = {
        enable = uf.settings.settings or false;
      };
    };

    # Services (nested: my.user.services.rclone)
    services = {
      rclone = {
        enable = uf.services.rclone or false;
      };
    };

    # Flat toggles from apps.* → my.user.*
    brave = {
      enable = uf.apps.browser.brave or false;
    };
    firefox = {
      enable = uf.apps.browser.firefox or false;
    };
    browser = {
      enable = uf.apps.browser.browser or false;
    };
    librewolf = {
      enable = uf.apps.browser.librewolf or false;
    };

    custompkgs = {
      enable = uf.apps.custompkgs.custompkgs or false;
    };

    git = {
      enable = uf.apps.dev.git or false;
    };
    ssh = {
      enable = uf.apps.dev.ssh or false;
    };
    nemo = {
      enable = uf.apps.dev.nemo or false;
    };
    devpkgs = {
      enable = uf.apps.dev.package or false;
    };

    nvim = {
      enable = uf.apps.editors.neovim or false;
    };
    zeditor = {
      enable = uf.apps.editors.zeditor or false;
    };
    vscodium = {
      enable = uf.apps.editors.vscodium or false;
    };

    game = {
      enable = uf.apps.gaming.game or false;
    };
    wine = {
      enable = uf.apps.gaming.wine or false;
    };

    media = {
      enable = uf.apps.media.media or false;
    };
    music = {
      enable = uf.apps.media.music or false;
    };
    office = {
      enable = uf.apps.media.office or false;
    };
    sosmed = {
      enable = uf.apps.media.sosmed or false;
    };

    packages = {
      enable = uf.apps.packages.packages or false;
    };
    security-tools = {
      enable = uf.apps.packages.pentest or false;
    };

    fastfetch = {
      enable = uf.apps.terminal.fastfetch or false;
    };
    fish = {
      enable = uf.apps.terminal.fish or false;
    };
    starship = {
      enable = uf.apps.terminal.starship or false;
    };
    tmux = {
      enable = uf.apps.terminal.tmux or false;
    };
    wezterm = {
      enable = uf.apps.terminal.wezterm or false;
    };

    # caelestia — flat (my.user.caelestia), flag from desktop.caelestia
    caelestia = {
      enable = uf.desktop.caelestia or false;
    };
  };

  programs.man.generateCaches = false;
  manual = {
    manpages.enable = false;
    html.enable = false;
    json.enable = false;
  };
  home.stateVersion = "25.11";
  programs.home-manager.enable = true;
}
