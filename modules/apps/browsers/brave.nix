{
  selfLib,
  pkgs,
  ...
}:

let
  inherit (selfLib.browserAddons { inherit pkgs; }) commonChromiumExtensions;
in
selfLib.mkModule {
  name = "apps.browsers.brave";
  description = "Brave browser configuration with maximal performance & privacy";

  flatpakCfg = {
    "com.brave.Browser" = {
      enable = true;

      # Overrides manual tambahan (seperti kebijakan sistem)
      overrides = {
        Context = {
          filesystems = [
            "/etc/brave:ro" # Diperlukan untuk membaca policies.json di /etc
            "xdg-run/psd" # Profile Sync Daemon tmpfs
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

      # Paket native untuk fallback jika flatpak dinonaktifkan
      nativePkgs = pkgs.brave;

      # Integrasi Home Manager program
      hmProgram = {
        name = "brave";
        extraConfig = {
          extensions = commonChromiumExtensions ++ [
            { id = "einpaelgookohagofgnnkcfjbkkgepnp"; } # Random User-Agent (Switcher)
            { id = "nplimhmoanghlebhdiboeellhgmgommi"; } # Tab Groups Extension
            { id = "nkbihfbeogaeaoehlefnkodbefgpgknn"; } # Metamask
            { id = "bhhhlbepdkbapadjdnnojkbgioiodbic"; } # Solflare Wallet
            { id = "dmkamcknogkgcdfhhbddcghachkejeap"; } # Keplr Wallet
          ];
        };
      };
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
