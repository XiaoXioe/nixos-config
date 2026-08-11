{
  userFeatures = {
    apps = {
      browsers = {
        firefox = false;
        brave = true;
        chromium = true;
        librewolf = false;
        tor-browser = true;
        zen = true;
        psd = true;
      };

      custom = {
        flatpak-repo = true;
        freqtrade = true;
        scrapers = true;
        tradingview = true;
      };
      office = {
        thunderbird = true;
        onlyoffice = true;
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
        zbar = true;
        downloader = true;
        music = true;
        dl-lagu = true;
      };

      terminal = {
        emulators = {
          alacritty = true;
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
  };
}
