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

  torBrowserPkg = selfLib.fetchCachePinned "tor_browser";
in
selfLib.mkModule {
  name = "apps.browsers.tor-browser";
  description = "Tor Browser configuration with sops-nix encrypted bookmarks";

  hmConfig = {
    home.packages = [ torBrowserPkg ];
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
