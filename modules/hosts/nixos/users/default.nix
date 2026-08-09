{
  userName = "klein-moretti";
  fullName = "Klein Moretti";
  defaultApps = {
    terminal = "foot";
    browser = "zen-beta";
    editor = "codium";
    fileManager = "dolphin";
  };
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
        firefox = false;
        brave = true;
        chromium = true;
        librewolf = false;
        tor-browser = true;
        zen = true;
        psd = true;
      };

      custom = {
        flatpak-repo = false;
        freqtrade = true;
        scrapers = true;
        tradingview = true;
      };
      office = {
        thunderbird = true;
        onlyoffice = true;
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
        zeditor = true;
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

    ai = {
      runtimes = {
        llama = true;
        ollama = true;
        ollama-to-llama = true;
      };
      agents = {
        agy-profile = true;
        agy-ide-profile = true;
        auth-agent = true;
      };
      interfaces = {
        open-webui = false;
      };
      tools = {
        mcp = true;
        kaggle = true;
        tools = true;
      };
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
      kernel = {
        stock = false;
        cachyos = true;
      };
      memory = true;
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
        cloudflare-warp = true;
        zapret = true;
      };
      scheduling = {
        ananicy = true;
        snapper = true;
        ssd-monitor = true;
      };
      boot-speedup = true;
      vaultwarden = true;
      flatpak = true;
      vmtouch = false;
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
