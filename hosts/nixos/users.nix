# lib/users.nix — Single user data for klein-moretti.
{
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

      custompkgs = true;

      dev = {
        nh = true;
        git = true;
        ssh = true;
        file-manager = true;
        mime-associations = true;
        packages = true;
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
        media = true;
        music = true;
        office = true;
        sosmed = true;
      };

      packages = {
        general = {
          enable = true;
          flatpaks = {
            "com.bitwarden.desktop".enable = false;
          };
        };
      };

      terminal = {
        btop = true;
        fastfetch = true;
        fish = true;
        starship = true;
        tmux = true;
        wezterm = false;
        foot = true;
        zellij = true;
      };
    };

    ai = {
      llama = true;
      ollama = true;
      open-webui = false;
      tools = true;
      mcp = true;
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
      packages = true;
      graphics = true;
      bootloader = true;
      kernel = true;
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
        enable = true;
        nandoroid = true;
      };
      xfce = false;
      theme = true;
      gnome = true;
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
      core = true;
      flatpak = true;
      rclone = true;
      restic = true;
      tmpfiles = true;
      btrfs-nocow-migration = true;
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
    };

    security = {
      gnupg = true;
      compat = false;
      secrets = true;
      hardening = true;
      auth = {
        enable = true;
        doas.enable = false;
        sudo.enable = false;
        sudo-rs.enable = true;
      };
      networking = true;
    };

    scripts = {
      custom-functions = true;
      agy-profile = true;
      agy-ide-profile = true;
      cek-cache = true;
      git-commits = true;
      dl-lagu = true;
      show-zombie-parents = true;
      ollama-to-llama = true;
      file-transfer = true;
      vpn = true;
      flake-update-interactive = true;
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
      packages = false;
    };
  };
}
