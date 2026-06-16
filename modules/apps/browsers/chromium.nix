{
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.browsers.chromium";
  description = "Chromium browser configuration";

  nixosConfig = {
    environment.etc."chromium/policies/managed/policies.json".text = builtins.toJSON {
      PasswordManagerEnabled = false;
      BrowserSignin = 0;
      RestoreOnStartup = 1;

      # --- Privasi & Telemetri ---
      MetricsReportingEnabled = false;
      SearchSuggestEnabled = false;
      SafeBrowsingProtectionLevel = 0;
      NetworkPredictionOptions = 2;
      DefaultSearchProviderEnabled = true;
      DefaultSearchProviderName = "DuckDuckGo";
      DefaultSearchProviderSearchURL = "https://duckduckgo.com/?q={searchTerms}";

    };
  };

  hmConfig = {
    programs.chromium = {
      enable = true;
      extensions = [
        { id = "ddkjiahejlhfcafbddmgiahcphecmpfh"; } # uBlock Origin Lite
        { id = "pkehgijcmpdhfbdbbnkijodmdjhbjlgp"; } # Privacy Badger
        { id = "nngceckbapebfimnlniiiahkandclblb"; } # Bitwarden Password Manager
        { id = "jplgfhpmjnbigmhklmmbgecoobifkmpa"; } # Proton-vpn
        { id = "hlepfoohegkhhmjieoechaddaejaokhf"; } # Refined GitHub
        { id = "lptnjkfjeaemenlipfaaocppmilaeejf"; } # ClearURLs
        { id = "mnjggcdmjocbbbhaepdhchncahnbgone"; } # SponsorBlock
        { id = "jinjaccalgkegednnccohejagnlnfdag"; } # Violentmonkey
        { id = "omkfmpieigblcllmkgbflkikinpkodlk"; } # Enhanced-h264ify
        { id = "jhnleheckmknfcgijgkadoemagpecfol"; } # Auto Tab Discard (suspend)
        { id = "cmpdlhmnmjhihmcfnigoememnffkimlk"; } # Catppuccin Macchiato
      ];
      commandLineArgs = [
        "--enable-gpu-rasterization"
        "--ignore-gpu-blocklist"
        "--disable-gpu-driver-bug-workarounds"
      ];
    };

    xdg.configFile."chromium-flags.conf".text = "--password-store=gnome-libsecret";
  };
}
