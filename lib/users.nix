# lib/users.nix — User definitions, per-user feature flags, and system features.
{
  # Users to provision on the system
  users = {
    klein-moretti = {
      fullName = "Klein Moretti (admin)";
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
            browser = true;
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
            pentest = true;
            general = true;
          };

          terminal = {
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
          environment = true;
          optimizations = true;
        };

        desktop = {
          dms = true;
          theme = true;
          kde = true;
          niri = true;
          greeter = true;
        };

        settings = {
          files = true;
        };

        services = {
          rclone = true;
          tmpfiles = true;
          networking = {
            dns = true;
            vpn = true;
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
        };

        scripts = {
          cek-cache = true;
          git-commits = true;
          dl-lagu = true;
          show-zombie-parents = true;
          ollama-to-llama = true;
        };

        virtualisation = {
          docker = true;
          waydroid = true;
          packages = true;
        };
      };
    };

    # Tambahkan user disini
    tamu = {
      fullName = "User Tamu";
      uid = 1001;
      extraGroups = [
        "networkmanager"
        "video"
        "audio"
        "render"
      ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIZ9JzZzktDyRcOpqMyit78cS0xx7NRj7Mak89HjsRLR u0_a185@localhost"
      ];
      userFeatures = {
        apps = {
          browsers = {
            firefox = true;
          };

          dev = {
            ssh = true;
            nemo = true;
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
            fastfetch = true;
            fish = true;
            wezterm = true;
          };
        };

        desktop = {
          dms = true;
          theme = true;
          kde = true;
          niri = true;
          greeter = true;
        };

        scripts = {
          cek-cache = true;
          dl-lagu = true;
          show-zombie-parents = true;
        };

        services = {
          rclone = true;
          networking = {
            dns = true;
            vpn = true;
          };
          scheduling = {
            snapper = true;
            ssd-monitor = true;
          };
          boot-speedup = true;
        };

        virtualisation = {
          waydroid = true;
        };
      };
    };
  };
}
