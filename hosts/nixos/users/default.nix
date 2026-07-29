{
  userName = "klein-moretti";
  fullName = "Klein Moretti";
  uid = 1000;
  extraGroups = [
    "wheel"
    "networkmanager"
    "video"
    "audio"
    "wireshark"
    "render"
    "i2c"
    "adbusers"
    "kvm"
    "dialout"
    "uucp"
  ];
  openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIZ9JzZzktDyRcOpqMyit78cS0xx7NRj7Mak89HjsRLR u0_a185@localhost"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEcEPafkivvHuS2FPHTQrlXvs/AEVkKE82V6hnIpAtRU klein-moretti@KleinMoretti"
  ];
  userFeatures = {
    apps = {
      browsers = {
        firefox = true;
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
        zathura = true;
      };
      social = {
        ayugram = true;
        discord = true;
        signal = true;
      };

      dev = {
        nh = true;
        git = true;
        ssh = true;
        file-manager = {
          dolphin = true;
          nemo = false;
        };
        mime-associations = true;
        languages = true;
        nix-tools = true;
        android = true;
        direnv = true;
        git-commits = true;
        flake-update-interactive = true;
        cek-cache = true;
      };

      editors = {
        neovim = false;
        vscodium = true;
        zeditor = false;
      };

      gaming = {
        game = true;
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
        btop = true;
        fastfetch = true;
        fish = true;
        starship = true;
        wezterm = false;
        foot = false;
        kitty = true;
        zellij = false;
        tools = true;
        fzf = true;
        zoxide = true;
        eza = true;
        functions = {
          file-transfer = true;
          show-zombie-parents = true;
          custom-functions = true;
        };
      };
    };

    ai = {
      llama = true;
      ollama = true;
      open-webui = false;
      tools = true;
      mcp = true;
      kaggle = true;
      agy-profile = true;
      agy-ide-profile = true;
      ollama-to-llama = true;
    };

    core = {
      nix = true;
      pipewire = {
        enable = true;
        pipewireEffects = {
          perfectEq = true;
          autogain = true;
        };
      };
      fonts = true;
      locale = true;
      system-tools = true;
      graphics = true;
      bootloader = true;
      kernel = true;
      kernel-xboreup = false;
      memory = true;
      power = true;
    };

    desktop = {
      kde = false;
      niri = {
        enable = true;
        dms = true;
      };
      hyprland = {
        enable = false;
        nandoroid = true;
      };
      xfce = false;
      theme = true;
      gnome = false;
      greeter = true;
    };

    hardware = {
      auto-mount = true;
      preservation = true;
    };

    settings = {
      files = true;
    };

    services = {
      system = {
        core = true;
        tmpfiles = true;
      };
      storage = {
        rclone = true;
        restic = true;
        btrfs-nocow-migration = true;
      };
      networking = {
        dns = true;
        vpn = true;
        openssh = true;
        "cloudflare-warp" = true;
        zapret = true;
      };
      scheduling = {
        ananicy = true;
        snapper = true;
        ssd-monitor = true;
      };
      boot-speedup = true;
      vaultwarden = true;
    };

    security = {
      password-manager = true;
      gnupg = true;
      compat = true;
      secrets = true;
      hardening = true;
      auth = {
        doas = false;
        sudo = false;
        sudo-rs = true;
        rtkit = true;
      };
      networking = true;
    };

    specialization = {
      retro-gaming = false;
      daily = false;
    };

    virtualisation = {
      docker = {
        enable = false;
        autoUpdate = false;
        "9router" = false;
      };
      libvirt = false;
      waydroid = true;
    };
  };
}
