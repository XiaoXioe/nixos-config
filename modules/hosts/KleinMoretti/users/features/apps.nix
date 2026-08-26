{
  userFeatures = {
    apps = {
      browsers = {
        firefox = false;
        brave = false;
        chromium = true;
        librewolf = false;
        tor-browser = true;
        zen = true;
        psd = true;
      };

      custom = {
        freqtrade = true;
        scrapers = true;
        tradingview = true;
      };
      office = {
        thunderbird = true;
        onlyoffice = false;
        protonmail = true;
        zathura = true;
        obsidian = true;
      };
      social = {
        materialgram = true;
        discord = true;
        signal = true;
      };

      dev = {
        nix = {
          nh = true;
          nix-tools = true;
          cek-cache = true;
          flake-update-interactive = true;
          apps-updater = true;
          cache-pins = true;
        };
        vcs = {
          git = true;
          git-commits = true;
        };
        environment = {
          direnv = true;
          ssh = true;
        };
        system = {
          android = true;
          file-manager = {
            dolphin = true;
            nemo = false;
          };
          languages = true;
          mime-associations = true;
        };
      };

      editors = {
        neovim = false;
        vscodium = true;
        zeditor = false;
      };

      gaming = {
        game = true;
        steam = true;
        emulators = true;
        wine = true;
      };

      media = {
        video = {
          mpv = true;
          yt-dlp = true;
          gallery-dl = true;
        };
        gthumb = true;
        ffmpeg = true;
        downloader = true;
        music = true;
        dl-lagu = true;
      };

      terminal = {
        emulators = {
          alacritty = false;
          foot = true;
          kitty = false;
          wezterm = false;
        };
        multiplexers = {
          zellij = true;
        };
        shells = {
          fish = true;
          starship = true;
        };
        utilities = {
          btop = true;
          eza = true;
          fastfetch = true;
          fzf = true;
          tools = true;
          zoxide = true;
          yazi = true;
          functions = {
            custom-functions = true;
            file-transfer = true;
            show-zombie-parents = true;
          };
        };
      };
    };

    security = {
      password-manager = {
        enable = true;
        bitwarden = true;
        proton-pass = false;
        ente-auth = true;
      };
    };
  };
}
