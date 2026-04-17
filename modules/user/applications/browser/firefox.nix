{
  config,
  lib,
  pkgs,
  selfLib,
  ...
}:

let
  cfg = config.my.user.firefox;
in
{
  options.my.user.firefox = {
    enable = selfLib.mkBoolOpt false "user browser configuration";
  };

  config = lib.mkIf cfg.enable {
    programs.firefox = {
      package = pkgs.firefox;
      enable = true;
      languagePacks = [
        "en-US"
        "id"
      ];
      policies = {
        DisableTelemetry = true;
        SearchSuggestEnabled = false;
        DisableFirefoxStudies = true;
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
              "Name" = "OpenStreetMap";
              "URLTemplate" = "https://www.openstreetmap.org/search?query={searchTerms}";
              "IconURL" = "https://www.openstreetmap.org/favicon.ico";
              "Alias" = "osm";
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

          #### FEATURES ###
          "layout.spellcheckDefault" = 1;
          # Use the systems native filechooser portal
          "widget.use-xdg-desktop-portal.file-picker" = 1;
          # allow adblockers to act everywhere. WARNING this is a security hole.
          "extensions.webextensions.restrictedDomains" = "";
          "media.webrtc.camera.allow-pipewire" = true;
          "browser.download.always_ask_before_handling_new_types" = true;

          #### DEBLOAT ###
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
          # Privacy: Disable automatic opening in new windows (manually still works)
          # https://gitlab.torproject.org/tpo/applications/tor-browser/-/issues/9881
          "browser.link.open_newwindow" = 3;
          # Privacy: Set all window open modes to abide above method
          "browser.link.open_newwindow.restriction" = 0;

          #### PRIVACY ###
          "privacy.resistFingerprinting" = "true";
          # disable sending downloaded files to the internet
          "browser.safebrowsing.downloads.remote.enabled" = false;
          "network.dns.disablePrefetch" = false;
          # redundancy: disable network prefetching
          "network.predictor.enabled" = false;
          # disable preloading websites when hovering over links
          "network.http.speculative-parallel-limit" = 0;
          # disable connecting to bookmarks when hovering over them
          "browser.places.speculativeConnect.enabled" = "false";
          "privacy.globalprivacycontrol.enabled" = true;
          "privacy.clearOnShutdown_v2.cookiesAndStorage" = true;
          "privacy.fingerprintingProtection" = true;

          "browser.contentblocking.category" = "strict";
          "extensions.pocket.enabled" = false;
          "browser.search.suggest.enabled" = false;
          "browser.search.suggest.enabled.private" = false;
          "browser.urlbar.suggest.searches" = false;
          # store media in cache only on private browsing
          "browser.privatebrowsing.forceMediaMemoryCache" = true;
          "network.http.referer.XOriginTrimmingPolicy" = 2;
          # Privacy: Disable CSP reporting
          # https://bugzilla.mozilla.org/show_bug.cgi?id=1964249
          "security.csp.reporting.enabled" = false;

          #### SECURITY ###
          #"browser.formfill.enable" = false;
          "pdfjs.enableScripting" = false;
          #"signon.autofillForms" = false
          # UNCLEAR
          "signon.formlessCapture.enabled" = false;
          # prevent scripts from moving or resizing windows
          "dom.disable_window_move_resize" = true;
          # Security: Disable remote debugging feature
          # https://gitlab.torproject.org/tpo/applications/tor-browser/-/issues/16222
          "devtools.debugger.remote-enabled" = false;
          # Security: Restrict directories from which extensions can be loaded (Unclear)
          # https://archive.is/DYjAM
          "extensions.enabledScopes" = 5;

          #### SSL ###
          # Security: Require safe SSL negotiation to avoid potentially MITMed sites
          "security.ssl.require_safe_negotiation" = true;
          # Security: Disable TLS1.3 0-RTT as key encryption may not be forward secret
          # https://github.com/tlswg/tls13-spec/issues/1001
          "security.tls.enable_0rtt_data" = 2;
          # Security: Enable strict public key pinning, prevents some MITM attacks
          "security.cert_pinning.enforcement_level" = 2;
          # Security: Enable CRLite to ensure that revoked certificates are detected
          "security.pki.crlite_mode" = 2;
          # Security: Treat unsafe negotiation as broken
          # https://wiki.mozilla.org/Security:Renegotiation
          # https://bugzilla.mozilla.org/1353705
          "security.ssl.treat_unsafe_negotiation_as_broken" = true;
          #  Security: Display more information on Insecure Connection warning pages
          # Test: https://badssl.com
          "browser.xul.error_pages.expert_bad_cert" = true;
        };
        ExtensionSettings = {
          # ATURAN GLOBAL: Blokir semua ekstensi yang tidak dideklarasikan
          "*" = {
            installation_mode = "blocked";
            # (Opsional) Pesan yang muncul jika Anda mencoba menginstal ekstensi dari browser
            blocked_install_message = "Ekstensi ini tidak dideklarasikan di NixOS / Home Manager!";
          };
          "uBlock0@raymondhill.net" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
            installation_mode = "force_installed";
          };
          "@testpilot-containers" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/file/4733069/multi_account_containers-8.3.7.xpi";
            installation_mode = "force_installed";
          };
          "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
            installation_mode = "force_installed";
          };
          "jid1-MnnxcxisBPnSXQ@jetpack" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/privacy-badger17/latest.xpi";
            installation_mode = "force_installed";
          };
          "{b9db16a4-6edc-47ec-a1f4-b86292ed211d}" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/file/4714322/video_downloadhelper-10.2.5.2.xpi";
            installation_mode = "force_installed";
          };
          "{9a41dee2-b924-4161-a971-7fb35c053a4a}" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/file/4295701/enhanced_h264ify-2.2.1.xpi";
            installation_mode = "force_installed";
          };
          "simple-tab-groups@drive4ik" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/file/4469818/simple_tab_groups-5.3.2.xpi";
            installation_mode = "force_installed";
          };
          "{76b37c8d-29d6-46b8-8c36-c7b6bce0c9ce}" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/file/3578635/nord_dark_theme-1.4.xpi";
            installation_mode = "force_installed";
          };
        };
      };
      profiles.${config.my.user.name} = {
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
              name = "Github Trending";
              url = "https://trendshift.io/";
            }
            {
              name = "Sutitle Cat";
              url = "https://subtilecat.com/";
            }
            {
              # Membuat folder di dalam bookmark
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
              # Menambahkan bookmark ke Bookmarks Toolbar
              name = "Toolbar Utama";
              toolbar = true; # Ini akan membuatnya muncul di barisan bawah address bar
              bookmarks = [
                {
                  name = "YouTube";
                  url = "https://youtube.com";

                }
                {
                  name = "Facebook";
                  url = "https://facebook.com";
                }
              ];
            }
          ];
        };
        settings = {
          "media.ffmpeg.vaapi.enabled" = true; # Aktifkan VA-API video acceleration
          "media.rdd-ffmpeg.enabled" = true; # Jalankan ffmpeg di proses terpisah (aman)
          "media.navigator.mediadatadecoder_vpx_enabled" = false; # Matikan decoding software untuk VP8/VP9
          "gfx.webrender.all" = true; # Paksa pakai WebRender
          "layers.acceleration.force-enabled" = true;
          "browser.send_pings" = false;
          "browser.urlbar.speculativeConnect.enabled" = false;
          "dom.security.https_only_mode" = true;
          "network.dns.disablePrefetch" = true;
          "privacy.donottrackheader.enabled" = true;
          "extensions.activeThemeID" = "{76b37c8d-29d6-46b8-8c36-c7b6bce0c9ce}";
          "webgl.force-enabled" = true; # Memaksa hardware acceleration
          "media.hardware-video-decoding.force-enabled" = true; # Paksa decoding video lewat GPU
          "widget.dmabuf.force-enabled" = true;
        };
      };
    };
  };
}
