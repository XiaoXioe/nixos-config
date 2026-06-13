{
  pkgs,
  config,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.browsers.firefox";
  description = "Firefox configuration for user";

  hmConfig = { config, userName, ... }: {
    programs.firefox = {
      package = pkgs.firefox;
      configPath = "${config.xdg.configHome}/mozilla/firefox";
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
        preferences = {
          "layout.spellcheckDefault" = 1;
          "widget.use-xdg-desktop-portal.file-picker" = 1;
          "extensions.webextensions.restrictedDomains" = "";
          "media.webrtc.camera.allow-pipewire" = true;
          "browser.download.always_ask_before_handling_new_types" = true;
          "browser.engagement.sidebar-button.has-used" = true;
          "browser.preferences.defaultPerformanceSettings.enabled" = false;
          "browser.display.document_color_use" = 0;
          "ui.systemUsesDarkTheme" = 1;
          "layout.css.prefers-color-scheme.content-override" = 0;
          "nimbus.rollouts.enabled" = false;
          "widget.gtk.overlay-scrollbars.enabled" = false;
          "browser.discovery.enabled" = false;
          "app.shield.optoutstudies.enabled" = false;
          "browser.topsites.contile.enabled" = false;
          "browser.urlbar.suggest.quicksuggest.sponsored" = false;
          "browser.urlbar.trending.featureGate" = false;
          "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
          "browser.newtabpage.activity-stream.feeds.snippets" = false;
          "browser.newtabpage.activity-stream.section.highlights.includePocket" = false;
          "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" = false;
          "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = false;
          "browser.newtabpage.activity-stream.section.highlights.includeVisited" = false;
          "browser.newtabpage.activity-stream.showSponsored" = false;
          "browser.newtabpage.activity-stream.system.showSponsored" = false;
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "browser.link.open_newwindow" = 3;
          "browser.link.open_newwindow.restriction" = 0;
          "privacy.resistFingerprinting" = false;
          "browser.safebrowsing.downloads.remote.enabled" = false;
          "network.dns.disablePrefetch" = true;
          "network.predictor.enabled" = false;
          "network.http.speculative-parallel-limit" = 0;
          "browser.places.speculativeConnect.enabled" = "false";
          "privacy.clearOnShutdown_v2.cookiesAndStorage" = true;
          "privacy.fingerprintingProtection" = true;
          "privacy.globalprivacycontrol.enabled" = true;
          "privacy.globalprivacycontrol.was_ever_enabled" = true;
          "browser.contentblocking.category" = "strict";
          "extensions.pocket.enabled" = false;
          "browser.search.suggest.enabled" = false;
          "browser.search.suggest.enabled.private" = false;
          "browser.urlbar.suggest.searches" = false;
          "browser.privatebrowsing.forceMediaMemoryCache" = true;
          "network.http.referer.XOriginTrimmingPolicy" = 0;
          "security.csp.reporting.enabled" = false;
          "extensions.formautofill.addresses.enabled" = false;
          "extensions.formautofill.creditCards.enabled" = false;
          "pdfjs.enableScripting" = false;
          "signon.formlessCapture.enabled" = false;
          "dom.disable_window_move_resize" = true;
          "devtools.debugger.remote-enabled" = false;
          "extensions.enabledScopes" = 5;
          "security.ssl.require_safe_negotiation" = true;
          "security.tls.enable_0rtt_data" = 2;
          "security.cert_pinning.enforcement_level" = 2;
          "security.pki.crlite_mode" = 2;
          "security.ssl.treat_unsafe_negotiation_as_broken" = true;
          "browser.xul.error_pages.expert_bad_cert" = true;
          "signon.rememberSignons" = false;
          "signon.autofillForms" = false;
          "signon.generation.enabled" = false;
          "signon.management.page.breach-alerts.enabled" = false;
        };
        ExtensionSettings = {
          "*" = {
            installation_mode = "blocked";
            blocked_install_message = "Ekstensi ini tidak dideklarasikan di NixOS / Home Manager!";
          };
          "uBlock0@raymondhill.net" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
            installation_mode = "force_installed";
            private_browsing = true;
          };
          "@testpilot-containers" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/multi-account-containers/latest.xpi";
            installation_mode = "force_installed";
          };
          "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
            installation_mode = "force_installed";
          };
          "{b9db16a4-6edc-47ec-a1f4-b86292ed211d}" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/video-downloadhelper/latest.xpi";
            installation_mode = "force_installed";
            private_browsing = true;
          };
          "{9a41dee2-b924-4161-a971-7fb35c053a4a}" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/enhanced-h264ify/latest.xpi";
            installation_mode = "force_installed";
          };
          "simple-tab-groups@drive4ik" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/simple-tab-groups/latest.xpi";
            installation_mode = "force_installed";
          };
          "webextension@metamask.io" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/ether-metamask/latest.xpi";
            installation_mode = "force_installed";
          };
          "keplr-extension@keplr.app" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/keplr/latest.xpi";
            installation_mode = "force_installed";
          };
          "{2adf0361-e6d8-4b74-b3bc-3f450e8ebb69}" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/catppuccin-mocha-blue-git/latest.xpi";
            installation_mode = "force_installed";
          };
          "vpn@proton.ch" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/proton-vpn-firefox-extension/latest.xpi";
            installation_mode = "force_installed";
          };
          "{a6c4a591-f1b2-4f03-b3ff-767e5bedf4e7}" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/user-agent-string-switcher/latest.xpi";
            installation_mode = "force_installed";
          };
          "{c2c003ee-bd69-42a2-b0e9-6f34222cb046}" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/auto-tab-discard/latest.xpi";
            installation_mode = "force_installed";
          };
        };
      };
      profiles.${userName} = {
        isDefault = true;
        bookmarks = {
          force = true;
          settings = [
            {
              name = "NixOS Packages";
              url = "https://search.nixos.org/packages";
            }
            {
              name = "NixOS Wiki";
              url = "https://nixos.wiki/";
            }
            {
              name = "Home manager options";
              url = "https://home-manager-options.extranix.com/";
            }
            {
              name = "Discourse Nixos";
              url = "https://discourse.nixos.org/";
            }
            {
              name = "Pekerjaan";
              bookmarks = [
                {
                  name = "Gmail";
                  url = "https://mail.google.com";
                }
                {
                  name = "GitHub";
                  url = "https://github.com";
                }
              ];
            }
            {
              name = "Toolbar Utama";
              toolbar = true;
              bookmarks = [
                {
                  name = "YouTube";
                  url = "https://youtube.com";
                }
                {
                  name = "Facebook";
                  url = "https://facebook.com";
                }
                {
                  name = "Reddit";
                  url = "https://www.reddit.com";
                }
              ];
            }
          ];
        };
        settings = {
          "browser.startup.page" = 3;
          "accessibility.force_disabled" = 1;
          "browser.urlbar.quickactions.enabled" = false;
          "media.ffmpeg.vaapi.enabled" = true;
          "media.rdd-ffmpeg.enabled" = true;
          "gfx.webrender.all" = true;
          "layers.acceleration.force-enabled" = true;
          "browser.send_pings" = false;
          "dom.security.https_only_mode" = true;
          "privacy.donottrackheader.enabled" = true;
          "extensions.activeThemeID" = "{2adf0361-e6d8-4b74-b3bc-3f450e8ebb69}";
          "webgl.force-enabled" = true;
          "media.hardware-video-decoding.force-enabled" = true;
          "widget.dmabuf.force-enabled" = true;
          "sidebar.verticalTabs" = true;
          "sidebar.revamp" = true;
          "identity.fxaccounts.enabled" = false;
          "toolkit.telemetry.enabled" = false;

          # Disable irritating first-run stuff
          "browser.disableResetPrompt" = true;
          "browser.feeds.showFirstRunUI" = false;
          "browser.messaging-system.whatsNewPanel.enabled" = false;
          "browser.shell.checkDefaultBrowser" = false;
          "browser.shell.defaultBrowserCheckCount" = 1;
          "browser.uitour.enabled" = false;
          "trailhead.firstrun.didSeeAboutWelcome" = true;
        };
      };
    };
  };
}
