{
  config,
  selfLib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (selfLib.browserAddonsFor { inherit pkgs inputs; })
    commonPrivacyPolicies
    mkBookmarkPoliciesTemplate
    mkBookmarkSecret
    ;

  appInfo = selfLib.appVersions.tor-browser;

  torBrowserNative = (selfLib.mkNativeApp pkgs) {
    name = "tor-browser";
    inherit (appInfo) version;
    src = selfLib.fetchApp pkgs "tor-browser";
    execPath = "tor-browser/Browser/start-tor-browser";
    binName = "tor-browser";
  };
in
selfLib.mkModule {
  name = "apps.browsers.tor-browser";
  description = "Tor Browser configuration with sops-nix encrypted bookmarks";

  hmConfig = {
    home.packages = [ torBrowserNative ];
  };

  nixosConfig = {
    environment.etc."tor-browser/policies/policies.json".source =
      config.sops.templates."tor-browser-policies.json".path;
    sops.secrets."tor-browser-bookmarks" = mkBookmarkSecret ./tor-bookmarks.enc;
    sops.templates."tor-browser-policies.json" = mkBookmarkPoliciesTemplate {
      ownerName = config.my.user.name;
      basePolicies = {
        inherit (commonPrivacyPolicies) DisableTelemetry DisableFirefoxStudies DontCheckDefaultBrowser;
      };
      bookmarkPlaceholder = config.sops.placeholder."tor-browser-bookmarks";
    };
  };
}
