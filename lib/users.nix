# lib/users.nix — Definisi semua user, fitur per-user, dan fitur sistem.
{
  # Daftar user yang akan diinstal di sistem
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
        startship = true;
        packages = true;
        custompkgs = true;
        editor_file = true;
        zeditor = true;
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
        distrobox = true;
        docker = true;
        settings = true;
        themes = true;

        services = {
          rclone = true;
        };

      };
    };

    #   Tamu = {
    #     fullName = "User Guests";
    #     uid = 1001;
    #     extraGroups = [
    #       "wheel"
    #       "networkmanager"
    #       "video"
    #       "audio"
    #       # "wireshark"
    #       "render"
    #       "i2c"
    #       "adbusers"
    #       "kvm"
    #     ];
    #     openssh.authorizedKeys.keys = [
    #       "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIZ9JzZzktDyRcOpqMyit78cS0xx7NRj7Mak89HjsRLR u0_a185@localhost"
    #     ];
    #     userFeatures = {
    #       dms = true;
    #       nvim = true;
    #       git = true;
    #       ssh = true;
    #       shell = true;
    #       packages = true;
    #     };
    #   };
  };
}
