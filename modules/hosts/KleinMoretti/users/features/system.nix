{
  userFeatures = {
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
        settings = true;
      };
      memory = true;
    };

    desktop = {
      kde = false;
      niri = {
        enable = true;
        noctalia = true;
        dms = true;
      };
      hyprland = {
        enable = false;
        noctalia = false;
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
        status-alert = true;
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
      documents = {
        stirling-pdf = false;
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
      podman = {
        enable = true;
        autoUpdate = true;
      };
      distrobox-pkg = true;
      libvirt = false;
      waydroid = true;
    };
  };
}
