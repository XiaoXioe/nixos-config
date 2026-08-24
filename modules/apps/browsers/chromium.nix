{
  selfLib,
  pkgs,
  ...
}:

let
  inherit (selfLib.browserAddonsFor { inherit pkgs; }) commonChromiumExtensions;
in
selfLib.mkModule {
  name = "apps.browsers.chromium";
  description = "Chromium browser via Nix binary cache — builtins.fetchClosure with Home Manager configuration";

  hmConfig = {
    programs.chromium = {
      enable = true;
      package = selfLib.fetchCachePinned pkgs "chromium";
      commandLineArgs = [
        "--password-store=gnome-libsecret"
        "--enable-gpu-rasterization"
        "--ignore-gpu-blocklist"
        "--disable-gpu-driver-bug-workarounds"
      ];
      extensions = [
        { id = "ddkjiahejlhfcafbddmgiahcphecmpfh"; } # uBlock Origin Lite
      ]
      ++ commonChromiumExtensions;
    };
  };

  # Kebijakan sistem browser (berlaku universal, tidak bergantung pada source package)
  nixosConfig = {
    environment.etc."chromium/policies/managed/policies.json".text = builtins.toJSON {
      ExtensionInstallForcelist = map (ext: ext.id) (
        [
          { id = "ddkjiahejlhfcafbddmgiahcphecmpfh"; } # uBlock Origin Lite
        ]
        ++ commonChromiumExtensions
      );

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
}
