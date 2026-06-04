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
        dms = true;
        caelestia = true;
        nvim = true;
        git = true;
        ssh = true;
        fish = true;
        tmux = true;
        fastfetch = true;
        wezterm = true;
        starship = true;
        packages = true;
        custompkgs = true;
        editor-file = true;
        zeditor = false;
        nemo = true;
        vscodium = true;
        devpkgs = true;
        securityTools = true;
        gaming = true;
        brave = true;
        media = true;
        music = true;
        sosmed = true;
        office = true;
        browser = true;
        firefox = true;
        librewolf = true;
        # distrobox = true;
        # docker = true;
        settings = true;
        themes = true;

        services = {
          rclone = true;
        };

      };
    };

    # To add a new user:
    # 1. Uncomment and customize the block below
    # 2. Shared home modules are at: modules/home/
    # 3. Adjust userFeatures to control which modules are enabled
    #
    # guest = {
    #   fullName = "Guest User";
    #   uid = 1001;
    #   extraGroups = [
    #     "wheel"
    #     "networkmanager"
    #     "video"
    #     "audio"
    #     "render"
    #     "i2c"
    #     "adbusers"
    #     "kvm"
    #   ];
    #   openssh.authorizedKeys.keys = [ ];
    #   userFeatures = {
    #     nvim = true;
    #     git = true;
    #     ssh = true;
    #     fish = true;
    #     packages = true;
    #   };
    # };
  };
}
