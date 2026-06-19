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
  ];
  openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIZ9JzZzktDyRcOpqMyit78cS0xx7NRj7Mak89HjsRLR u0_a185@localhost"
  ];
  userFeatures = {
    apps = {
      browsers = {
        brave = true;
        firefox = true;
        chromium = true;
        librewolf = true;
      };

      custompkgs = true;

      dev = {
        git = true;
        ssh = true;
        nemo = true;
        packages = true;
      };

      editors = {
        neovim = true;
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
        general = true;
      };

      terminal = {
        btop = true;
        fastfetch = true;
        fish = true;
        starship = true;
        tmux = true;
        wezterm = true;
      };
    };

    ai = {
      llama = true;
      ollama = true;
      open-webui = true;
      tools = true;
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
      optimizations = true;
    };

    desktop = {
      kde = false;
      niri = true;
      hyprland = false;
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
      rclone = true;
      tmpfiles = true;
      networking = {
        dns = true;
        vpn = true;
        openssh = true;
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
      compat = true;
      pentest = true;
      secrets = true;
      hardening = true;
      networking = true;
    };

    scripts = {
      cek-cache = true;
      git-commits = true;
      dl-lagu = true;
      show-zombie-parents = true;
      ollama-to-llama = true;
      file-transfer = true;
    };

    specialization = {
      retro-gaming = false;
      daily = false;
    };

    virtualisation = {
      docker = {
        enable = true;
        autoUpdate = true;
        "9router" = true;
      };
      libvirt = true;
      waydroid = true;
      packages = true;
    };
  };
}
