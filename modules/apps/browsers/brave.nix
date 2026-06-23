{
  selfLib,
  pkgs,
  ...
}:

selfLib.mkApp {
  name = "apps.browsers.brave";
  description = "Brave browser configuration with maximal performance & privacy";

  flatpak = {
    appId = "com.brave.Browser";

    # Overrides manual tambahan (seperti kebijakan sistem)
    overrides = {
      Context = {
        filesystems = [
          "/etc/brave:ro" # Diperlukan untuk membaca policies.json di /etc
        ];
      };
    };

    # Otomatis membuat symlink dan mendaftarkannya di sandbox filesystem overrides
    symlinks = [
      {
        host = ".config/BraveSoftware";
        guest = "config/BraveSoftware";
      }
    ];

    # Menulis file flags
    flags = {
      file = "config/brave-flags.conf";
      text = ''
        --password-store=gnome-libsecret
        --enable-gpu-rasterization
        --ignore-gpu-blocklist
        --enable-features=WebUIDarkMode,Containers
        --disable-gpu-driver-bug-workarounds
        --disable-reading-from-canvas
        --no-pings
      '';
    };
  };

  # Paket native untuk fallback jika flatpak dinonaktifkan
  native = {
    package = pkgs.brave;
  };

  # Integrasi Home Manager program
  hmProgram = {
    name = "brave";
    extraConfig = {
      extensions = [
        { id = "pkehgijcmpdhfbdbbnkijodmdjhbjlgp"; } # Privacy Badger
        { id = "nngceckbapebfimnlniiiahkandclblb"; } # Bitwarden Password Manager
        { id = "jplgfhpmjnbigmhklmmbgecoobifkmpa"; } # Proton-vpn
        { id = "hlepfoohegkhhmjieoechaddaejaokhf"; } # Refined GitHub
        { id = "lptnjkfjeaemenlipfaaocppmilaeejf"; } # ClearURLs
        { id = "mnjggcdmjocbbbhaepdhchncahnbgone"; } # SponsorBlock
        { id = "jinjaccalgkegednnccohejagnlnfdag"; } # Violentmonkey
        { id = "omkfmpieigblcllmkgbflkikinpkodlk"; } # Enhanced-h264ify
        { id = "jhnleheckmknfcgijgkadoemagpecfol"; } # Auto Tab Discard (suspend)
        { id = "einpaelgookohagofgnnkcfjbkkgepnp"; } # Random User-Agent (Switcher)
        { id = "nplimhmoanghlebhdiboeellhgmgommi"; } # Tab Groups Extension
        { id = "cmpdlhmnmjhihmcfnigoememnffkimlk"; } # Catppuccin Macchiato
      ];
    };
  };

  # Kebijakan sistem browser (berlaku universal baik Flatpak maupun Native)
  nixosConfig = {
    environment.etc."brave/policies/managed/policies.json".text = builtins.toJSON {
      PasswordManagerEnabled = false;
      BrowserSignin = 0;
      RestoreOnStartup = 1;
      BraveAIChatEnabled = false;
      BraveP3AEnabled = false;
      BraveStatsPingEnabled = false;
      BraveWebDiscoveryEnabled = false;
      BraveWalletDisabled = true;
      BraveRewardsDisabled = true;
      BraveVPNDisabled = true;
    };
  };
}
