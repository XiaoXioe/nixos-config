{
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.browsers.brave";
  description = "Brave browser configuration with maximal performance & privacy";

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

  hmConfig = {
    programs.brave = {
      enable = true;
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
      commandLineArgs = [
        "--enable-gpu-rasterization" # Memaksa akselerasi GPU untuk rendering
        "--ignore-gpu-blocklist" # Memaksa fitur GPU meskipun driver tidak dikenali secara resmi

        # --- PAKSA HARDWARE DECODING (VA-API) ---
        "--enable-features=WebUIDarkMode,Containers"
        "--disable-gpu-driver-bug-workarounds" # Mengabaikan aturan pembatasan dari Chromium untuk GPU lama

        # --- Privasi Tambahan ---
        "--disable-reading-from-canvas" # Mencegah canvas fingerprinting
        "--no-pings" # Mencegah pengiriman hyperlink auditing pings
      ];
    };

    xdg.configFile."brave-flags.conf".text = "--password-store=gnome-libsecret";
  };
}
