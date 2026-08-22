{
  selfLib,
  pkgs,
  ...
}:

let
  inherit (selfLib.browserAddonsFor { inherit pkgs; }) commonChromiumExtensions;
  appInfo = selfLib.appVersions.chromium;

  chromiumNative = (selfLib.mkNativeApp pkgs) {
    name = "chromium";
    inherit (appInfo) version;
    src = selfLib.fetchApp pkgs "chromium";
    execPath = "usr/lib/chromium/chromium";
    binName = "chromium";
    extraArgs = [
      "--password-store=gnome-libsecret"
      "--enable-gpu-rasterization"
      "--ignore-gpu-blocklist"
      "--disable-gpu-driver-bug-workarounds"
    ];
  };
in
selfLib.mkModule {
  name = "apps.browsers.chromium";
  description = "Chromium browser native configuration with pure upstream binary";

  hmConfig = {
    home.packages = [ chromiumNative ];
  };

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
