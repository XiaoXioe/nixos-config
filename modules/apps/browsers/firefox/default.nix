{
  pkgs,
  inputs ? { },
  selfLib,
  ...
}:

let
  inherit (selfLib.browserAddonsFor { inherit pkgs inputs; })
    amoAddons
    resolveAddons
    ;

  # Extensions resolved directly into .xpi derivation packages for native profile symlinking
  firefoxExtensions = resolveAddons (
    with amoAddons;
    [
      ublock-origin
      bitwarden
      multi-account-containers
      tampermonkey
    ]
  );

  baseSettings = {
    "browser.startup.page" = 3; # Restore previous session
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
    "toolkit.policies.perUserDir" = true;
    "privacy.trackingprotection.fingerprinting.enabled" = true;
    "privacy.trackingprotection.cryptomining.enabled" = true;

    # Automatically enable profile-installed extensions
    "extensions.autoDisableScopes" = 0;
    "extensions.enabledScopes" = 15;

    # ── Search Engine Configuration ─────────────────────────────────────
    "browser.search.defaultenginename" = "DuckDuckGo";
    "browser.search.selectedEngine" = "DuckDuckGo";
    "browser.search.region" = "US";
    "browser.search.suggest.enabled" = false;
    "browser.urlbar.suggest.searches" = false;
    "browser.search.hiddenOneOffs" =
      "Google,Yahoo,Bing,Amazon.com,eBay,Wikipedia,Wikipedia (en),Perplexity,Ecosia,Qwant";

    # ── Matikan Semua Autofill & Password Prompts ───────────────────────
    "signon.rememberSignons" = false;
    "signon.autofillForms" = false;
    "signon.generation.enabled" = false;
    "signon.firefoxRelay.feature" = "disabled";
    "signon.management.page.breach-alerts.enabled" = false;
    "extensions.formautofill.addresses.enabled" = false;
    "extensions.formautofill.creditCards.enabled" = false;
    "extensions.formautofill.heuristics.enabled" = false;
    "browser.formfill.enable" = false;
  };

  commonSearch = {
    default = "ddg";
    privateDefault = "ddg";
    force = true;
    engines = {
      "ddg" = {
        metaData.hidden = false;
        definedAliases = [ "@ddg" ];
      };
      "brave" = {
        name = "Brave Search";
        urls = [
          {
            template = "https://search.brave.com/search";
            params = [
              {
                name = "q";
                value = "{searchTerms}";
              }
            ];
          }
        ];
        icon = "https://cdn.search.brave.com/serp/v1/static/brand/eebf5f2ce06b0b0ee6bbd72d7e18621d4618b9663471d42463c692d019068072-brave-lion-favicon.png";
        definedAliases = [ "@brave" ];
      };
      "google".metaData.hidden = true;
      "bing".metaData.hidden = true;
      "amazondotcom-us".metaData.hidden = true;
      "ebay".metaData.hidden = true;
      "wikipedia".metaData.hidden = true;
      "perplexity".metaData.hidden = true;
      "ecosia".metaData.hidden = true;
      "qwant".metaData.hidden = true;
    };
  };

  userChrome = ''
    .tab-close-button { display: none !important; }
  '';
in
selfLib.mkModule {
  name = "apps.browsers.firefox";
  description = "Firefox ESR inside Debian Distrobox with declarative Home Manager profile and direct native extensions";

  preservation = {
    userDirectories = [
      ".cache/mozilla"
      ".mozilla"
    ];
  };

  nixosConfig = {
    environment.sessionVariables = {
      MOZ_ENABLE_WAYLAND = "1";
    };
  };

  distroboxCfg = selfLib.distrobox.debian {

    packages = [ "firefox-esr" ];
    package = pkgs.firefox-esr;
    binName = "firefox-esr";
    deltaUpdates = true;
    env = {
      MOZ_LEGACY_PROFILES = "1";
      MOZ_ENABLE_WAYLAND = "1";
    };
    hmProgram = {
      name = "firefox";
      extraConfig = {
        configPath = ".mozilla/firefox";
        profiles = {
          default = {
            id = 0;
            name = "default";
            isDefault = true;
            settings = baseSettings;
            search = commonSearch;
            inherit userChrome;

            # Direct native .xpi extensions generation into ~/.mozilla/firefox/default/extensions/
            extensions.packages = firefoxExtensions;
          };

          hardened = {
            id = 1;
            name = "hardened";
            isDefault = false;
            settings = baseSettings // {
              "privacy.firstparty.isolate" = true;
              "privacy.trackingprotection.fingerprinting.enabled" = true;
              "privacy.trackingprotection.cryptomining.enabled" = true;
              "dom.event.clipboardevents.enabled" = false;
              "media.peerconnection.enabled" = false;
            };
            search = commonSearch;
            inherit userChrome;
            extensions.packages = firefoxExtensions;
          };
        };
      };
    };
  };

  hmConfig = {
    home.sessionVariables = {
      MOZ_LEGACY_PROFILES = "1";
    };

    # Multi-profile desktop entry with actions
    xdg.desktopEntries.firefox = {
      name = "Firefox ESR (Distrobox)";
      genericName = "Web Browser";
      comment = "Browse the World Wide Web via Debian Distrobox";
      exec = "firefox-esr %u";
      icon = "firefox-esr";
      terminal = false;
      categories = [
        "Network"
        "WebBrowser"
      ];
      mimeType = [
        "text/html"
        "text/xml"
        "application/xhtml+xml"
        "application/xml"
        "application/vnd.mozilla.xul+xml"
        "application/rss+xml"
        "application/rdf+xml"
        "image/gif"
        "image/jpeg"
        "image/png"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
      ];
      actions = {
        "new-window" = {
          name = "New Window";
          exec = "firefox-esr --new-window %u";
        };
        "new-private-window" = {
          name = "New Private Window";
          exec = "firefox-esr --private-window %u";
        };
        "profile-hardened" = {
          name = "Open Hardened Profile";
          exec = "firefox-esr -P hardened %u";
        };
        "profile-manager" = {
          name = "Profile Manager";
          exec = "firefox-esr --ProfileManager";
        };
      };
      settings = {
        StartupWMClass = "firefox-esr";
      };
    };
  };
}
