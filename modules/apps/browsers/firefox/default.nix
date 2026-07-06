{
  pkgs,
  selfLib,
  inputs,
  ...
}:
let
  inherit (selfLib.browserAddons { inherit pkgs inputs; })
    lock-false
    lock-true
    lock-empty-string
    lock
    addons
    tampermonkey
    keplr
    solflare-wallet
    ;

  # Import separated data files
  bookmarksList = import ./bookmarks.nix;
  policyPreferences = import ./policies.nix {
    inherit
      lock
      lock-true
      lock-false
      lock-empty-string
      ;
  };
in
selfLib.mkModule {
  name = "apps.browsers.firefox";
  description = "Firefox configuration for user";

  nixosConfig = {
    environment.sessionVariables = {
      MOZ_ENABLE_WAYLAND = "1";
    };
  };

  hmConfig =
    hmOpts:
    let
      baseSettings = {
        "browser.startup.page" = 3;
        "accessibility.force_disabled" = 1;
        "browser.urlbar.quickactions.enabled" = false;
        "widget.dmabuf.force-enabled" = true;
        "sidebar.verticalTabs" = true;
        "sidebar.revamp" = true;
        "browser.disableResetPrompt" = true;
        "browser.feeds.showFirstRunUI" = false;
        "browser.messaging-system.whatsNewPanel.enabled" = false;
        "browser.uitour.enabled" = false;
        "trailhead.firstrun.didSeeAboutWelcome" = true;
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "extensions.autoDisableScopes" = 0;
      };

      bookmarks = {
        force = true;
        settings = bookmarksList;
      };

      userChrome = ''
        .tab-close-button { display: none !important; }
      '';
    in
    {
      programs.firefox = {
        package = pkgs.firefox;
        configPath = "${hmOpts.config.xdg.configHome}/mozilla/firefox";
        enable = true;
        languagePacks = [
          "en-US"
          "id"
        ];
        policies = {
          DisableTelemetry = true;
          SearchSuggestEnabled = false;
          DisableFirefoxStudies = true;
          PasswordManagerEnabled = false;
          DisableFirefoxAccounts = true;
          DontCheckDefaultBrowser = true;
          SearchEngines = {
            Remove = [
              "eBay"
              "Google"
              "Bing"
              "Ecosia"
              "Wikipedia"
              "Perplexity"
            ];
            Add = [
              {
                "Name" = "Brave Search";
                "URLTemplate" = "https://search.brave.com/search?q={searchTerms}&summary=0";
                "IconURL" =
                  "https://cdn.search.brave.com/serp/v1/static/brand/eebf5f2ce06b0b0ee6bbd72d7e18621d4618b9663471d42463c692d019068072-brave-lion-favicon.png";
                "Alias" = "brave";
              }
              {
                "Name" = "DuckDuckGo";
                "URLTemplate" = "https://duckduckgo.com/?q={searchTerms}&ia=web&assist=false";
                "IconURL" = "https://duckduckgo.com/favicon.ico";
                "Alias" = "ddg";
                "Description" = "Duckduckgo without AI integrations";
              }
              {
                "Name" = "Wikipedia";
                "URLTemplate" = "https://en.wikipedia.org/wiki/Special:Search?go=Go&search={searchTerms}";
                "IconURL" = "https://en.wikipedia.org/favicon.ico";
                "Alias" = "wiki";
              }
            ];
            Default = "DuckDuckGo";
          };
          EnableTrackingProtection = {
            Value = true;
            Locked = true;
            Cryptomining = true;
            Fingerprinting = true;
          };
          PopupBlocking = {
            Default = true;
            Locked = true;
          };
          DisablePocket = true;
          NetworkPrediction = false;
          Preferences = policyPreferences;
        };

        profiles = {
          ${hmOpts.config.home.username} = {
            isDefault = true;
            id = 0;
            inherit bookmarks userChrome;
            extensions.packages =
              (with addons; [
                ublock-origin
                multi-account-containers
                bitwarden
                simple-tab-groups
                auto-tab-discard
                metamask
                container-proxy
                tampermonkey
              ])
              ++ [
                keplr
                solflare-wallet
              ];
            settings = baseSettings // {
              "privacy.resistFingerprinting" = false;
              "privacy.fingerprintingProtection" = true;
              "privacy.fingerprintingProtection.overrides" =
                "+AllTargets,-CSSPrefersColorScheme,-ReduceTimerPrecision";
              "privacy.clearOnShutdown_v2.cookiesAndStorage" = false;
              "media.peerconnection.enabled" = true;
              "webgl.disabled" = false;
              "geo.enabled" = true;
            };
          };
          "${hmOpts.config.home.username}-hardened" = {
            isDefault = false;
            id = 1;
            inherit bookmarks userChrome;
            extensions.packages = (
              with addons;
              [
                ublock-origin
                bitwarden
                privacy-badger
                canvasblocker
                localcdn
                user-agent-string-switcher
                proton-vpn
                auto-tab-discard
                simple-tab-groups
                tampermonkey
              ]
            );
            # ++ [
            # ];
            settings = baseSettings // {
              "privacy.resistFingerprinting" = false;
              "privacy.fingerprintingProtection" = true;
              "privacy.clearOnShutdown_v2.cookiesAndStorage" = true;
              "privacy.clearOnShutdown_v2.cache" = true;
              "privacy.sanitize.sanitizeOnShutdown" = true;
              "privacy.clearOnShutdown_v2.historyFormDataAndDownloads" = false;
              "privacy.clearOnShutdown_v2.browsingHistoryAndDownloads" = false;
              "media.peerconnection.enabled" = false;
              "webgl.disabled" = true;
              "geo.enabled" = false;
              "browser.privatebrowsing.autostart" = false;
              "device.sensors.enabled" = false;
            };
          };
        };
      };
    };
}
