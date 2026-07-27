{
  config,
  selfLib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (selfLib.browserAddons { inherit pkgs inputs; })
    commonPrivacyPolicies
    mkBookmarkPoliciesTemplate
    mkBookmarkSecret
    ;
in
selfLib.mkModule {
  name = "apps.browsers.tor-browser";
  description = "Tor Browser configuration with sops-nix encrypted bookmarks";

  nixosConfig = {
    environment.etc."tor-browser/policies/policies.json".source =
      config.sops.templates."tor-browser-policies.json".path;
    sops.secrets."tor-browser-bookmarks" = mkBookmarkSecret (
      selfLib.secretBinary "browsers/tor-browser-bookmarks.enc"
    );
    sops.templates."tor-browser-policies.json" = mkBookmarkPoliciesTemplate {
      ownerName = config.my.user.name;
      basePolicies = {
        inherit (commonPrivacyPolicies) DisableTelemetry DisableFirefoxStudies DontCheckDefaultBrowser;
      };
      bookmarkPlaceholder = config.sops.placeholder."tor-browser-bookmarks";
    };
  };

  flatpakCfg = {
    "org.torproject.torbrowser-launcher" = {
      enable = true;

      overrides = {
        Context = {
          filesystems = [
            "xdg-run/psd" # Profile Sync Daemon tmpfs
          ];
        };
      };

      # Symlinks to keep data persistent and synced between native and Flatpak
      symlinks = [
        {
          host = ".local/share/torbrowser";
          guest = "data/torbrowser";
        }
      ];

      # Native package fallback if Flatpak is disabled
      nativePkgs = pkgs.tor-browser;
    };
  };
}
