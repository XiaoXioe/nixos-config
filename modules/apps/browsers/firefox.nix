{
  pkgs,
  selfLib,
  inputs,
  ...
}:
let
  lock-false = {
    Value = false;
    Status = "locked";
  };
  lock-true = {
    Value = true;
    Status = "locked";
  };
  lock-empty-string = {
    Value = "";
    Status = "locked";
  };
  lock = value: {
    Value = value;
    Status = "locked";
  };

  addons = inputs.firefox-addons.packages.${pkgs.system};
  video-downloadhelper = addons.video-downloadhelper.overrideAttrs (old: {
    meta = (old.meta or { }) // {
      license = [ ];
    };
  });
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
    { config, userName, ... }:
    let
      buildAmoAddon =
        {
          pname,
          addonId,
          sha256,
          slug ? pname,
          version ? "latest",
        }:
        pkgs.stdenv.mkDerivation {
          name = "${pname}-${version}";
          src = pkgs.fetchurl {
            url = "https://addons.mozilla.org/firefox/downloads/latest/${slug}/latest.xpi";
            inherit sha256;
          };
          preferLocalBuild = true;
          allowSubstitutes = false;
          buildCommand = ''
            dst="$out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}"
            mkdir -p "$dst"
            ln -s "$src" "$dst/${addonId}.xpi"
          '';
        };

      keplr = buildAmoAddon {
        pname = "keplr";
        addonId = "keplr-extension@keplr.app";
        sha256 = "166ggld6b4lh1hvsm2bd0g8b7kp7y9ln2fhf7jfcmx0pbd9z4zzp";
      };

      catppuccin-mocha-blue = buildAmoAddon {
        pname = "catppuccin-mocha-blue";
        addonId = "{2adf0361-e6d8-4b74-b3bc-3f450e8ebb69}";
        slug = "catppuccin-mocha-blue-git";
        sha256 = "0fgl7jcx5h3p5kgp3pcas89s25vjbyx7rzp0hs38s8l0ij6mp0y7";
      };

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
        "extensions.activeThemeID" = "{2adf0361-e6d8-4b74-b3bc-3f450e8ebb69}";
        "extensions.autoDisableScopes" = 0;
      };

      bookmarksList = [
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
          Preferences = {
            # ==========================================
            # 1. Dark Mode & Tampilan (Appearance)
            # ==========================================
            "ui.systemUsesDarkTheme" = lock 1; # Paksa Firefox mendeteksi sistem menggunakan tema gelap
            "layout.css.prefers-color-scheme.content-override" = lock 0; # Paksa prefers-color-scheme situs web menjadi gelap
            "browser.display.document_color_use" = lock 0; # Gunakan warna dokumen dari situs kecuali untuk tema high-contrast
            "widget.gtk.overlay-scrollbars.enabled" = lock-false; # Tampilkan scrollbar GTK biasa (bukan overlay/tersembunyi)

            # ==========================================
            # 2. Privasi & Keamanan Konten (Privacy & Content Security)
            # ==========================================
            "privacy.donottrackheader.enabled" = lock-true; # Kirimkan header "Do Not Track" ke semua situs web
            "privacy.globalprivacycontrol.enabled" = lock-true; # Aktifkan Global Privacy Control (GPC) untuk membatasi penjualan data pribadi
            "privacy.globalprivacycontrol.was_ever_enabled" = lock-true; # Konfirmasi status GPC pernah diaktifkan
            "browser.contentblocking.category" = lock "strict"; # Setel tingkat pemblokiran pelacak bawaan ke tingkat Ketat (Strict)
            "browser.send_pings" = lock-false; # Blokir pengiriman ping audit klik tautan oleh website
            "dom.security.https_only_mode" = lock-true; # Paksa mode HTTPS-Only untuk semua koneksi situs web
            "security.csp.reporting.enabled" = lock-false; # Matikan pelaporan Content Security Policy (CSP) untuk cegah kebocoran data navigasi
            "browser.privatebrowsing.forceMediaMemoryCache" = lock-true; # Paksa penyimpanan cache media di memori RAM (bukan disk) saat Private Browsing
            "browser.privatebrowsing.autostart" = lock-false; # Jangan pernah jalankan mode private secara otomatis di startup

            # ==========================================
            # 3. Kredensial & Pengisian Otomatis (Credentials & Autofill)
            # ==========================================
            "signon.rememberSignons" = lock-false; # Matikan penawaran penyimpanan sandi bawaan Firefox (direkomendasikan pakai Bitwarden)
            "signon.autofillForms" = lock-false; # Matikan pengisian sandi otomatis sebelum diklik (mencegah pencurian kredensial tak terlihat)
            "signon.generation.enabled" = lock-false; # Matikan generator sandi bawaan Firefox
            "signon.management.page.breach-alerts.enabled" = lock-false; # Matikan peringatan kebocoran sandi bawaan Firefox
            "signon.formlessCapture.enabled" = lock-false; # Matikan perekaman username/password pada form tanpa tombol submit resmi
            "extensions.formautofill.addresses.enabled" = lock-false; # Matikan pengisian otomatis untuk alamat rumah
            "extensions.formautofill.creditCards.enabled" = lock-false; # Matikan pengisian otomatis untuk kartu kredit

            # ==========================================
            # 4. Keamanan Jaringan & Sertifikat (Network & Cert Security)
            # ==========================================
            "security.ssl.require_safe_negotiation" = lock-true; # Wajibkan negosiasi SSL yang aman untuk hindari serangan downgrade TLS
            "security.tls.enable_0rtt_data" = lock 2; # Batasi data 0-RTT TLS 1.3 untuk cegah serangan replay
            "security.cert_pinning.enforcement_level" = lock 2; # Paksa tingkat penegakan Certificate Pinning secara ketat
            "security.pki.crlite_mode" = lock 2; # Aktifkan pemeriksaan pencabutan sertifikat SSL secara lokal menggunakan CRLite
            "browser.sessionstore.restore_on_demand" = lock-true; # Mencegah agar tab reguler tidak dimuat sampai diklik
            "browser.sessionstore.restore_pinned_tabs_on_demand" = lock-true; # Mencegah agar tab disematkan tidak dimuat sampai diklik

            # ==========================================
            # 5. Jaringan & Performa (Network & Performance)
            # ==========================================
            "network.dns.disablePrefetch" = lock-true; # Matikan prefetch DNS sebelum link diklik untuk mencegah kebocoran kueri DNS
            "network.predictor.enabled" = lock-false; # Matikan prediksi jaringan berdasarkan riwayat navigasi Anda
            "network.http.speculative-parallel-limit" = lock 0; # Batasi pre-koneksi paralel HTTP spekulatif menjadi nol
            "browser.places.speculativeConnect.enabled" = lock-false; # Matikan koneksi spekulatif saat mengarahkan kursor ke link
            "browser.preferences.defaultPerformanceSettings.enabled" = lock-true; # Aktifkan pengaturan performa bawaan

            # ==========================================
            # 6. Pencarian, Rekomendasi & Iklan (Search & Recommendations)
            # ==========================================
            "browser.discovery.enabled" = lock-false; # Matikan rekomendasi konten personal di panel baru/beranda
            "browser.search.suggest.enabled" = lock-false; # Matikan saran pencarian saat mengetik di bilah alamat
            "browser.search.suggest.enabled.private" = lock-false; # Matikan saran pencarian di mode Private Browsing
            "browser.urlbar.suggest.searches" = lock-false; # Sembunyikan opsi riwayat pencarian lama di bilah alamat
            "browser.urlbar.suggest.quicksuggest.sponsored" = lock-false; # Matikan saran sponsor di url bar
            "browser.urlbar.trending.featureGate" = lock-false; # Matikan saran tren pencarian di url bar
            "browser.topsites.contile.enabled" = lock-false; # Matikan iklan/rekomendasi top sites dari Contile
            "extensions.pocket.enabled" = lock-false; # Matikan integrasi Pocket secara keseluruhan

            # ==========================================
            # 7. Pengaturan Tab Baru & Artikel (Newtab Activity Stream)
            # ==========================================
            "browser.newtabpage.activity-stream.feeds.section.topstories" = lock-false; # Matikan artikel Pocket di tab baru
            "browser.newtabpage.activity-stream.section.highlights.includePocket" = lock-false; # Sembunyikan Pocket dari highlight tab baru
            "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" = lock-false; # Sembunyikan bookmark dari highlight tab baru
            "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = lock-false; # Sembunyikan riwayat unduhan dari highlight tab baru
            "browser.newtabpage.activity-stream.section.highlights.includeVisited" = lock-false; # Sembunyikan situs yang dikunjungi dari highlight tab baru
            "browser.newtabpage.activity-stream.showSponsored" = lock-false; # Sembunyikan konten sponsor di tab baru
            "browser.newtabpage.activity-stream.system.showSponsored" = lock-false; # Matikan iklan sistem sponsor di tab baru
            "browser.newtabpage.activity-stream.showSponsoredTopSites" = lock-false; # Sembunyikan situs populer sponsor di tab baru

            # ==========================================
            # 8. Umum & Integrasi Sistem (General & System Integration)
            # ==========================================
            "layout.spellcheckDefault" = lock 1; # Aktifkan spellcheck hanya untuk textarea multiline
            "widget.use-xdg-desktop-portal.file-picker" = lock 1; # Gunakan portal file picker bawaan desktop environment (GTK/KDE)
            "extensions.webextensions.restrictedDomains" = lock-empty-string; # Hapus batasan modifikasi ekstensi pada domain khusus Mozilla
            "media.webrtc.camera.allow-pipewire" = lock-true; # Izinkan transmisi kamera menggunakan PipeWire di Linux
            "browser.download.always_ask_before_handling_new_types" = lock-true; # Selalu minta konfirmasi aksi ketika mengunduh tipe file baru
            "browser.engagement.sidebar-button.has-used" = lock-true; # Tandai tombol sidebar sudah pernah digunakan untuk hindari tutorial pemula
            "browser.link.open_newwindow" = lock 3; # Buka tautan eksternal di tab baru (bukan jendela baru)
            "browser.link.open_newwindow.restriction" = lock 0; # Paksa semua pop-up eksternal dibuka sebagai tab baru
            "browser.safebrowsing.downloads.remote.enabled" = lock-false; # Matikan pengiriman metadata file unduhan ke Google Safe Browsing demi privasi
            "pdfjs.enableScripting" = lock-false; # Matikan eksekusi JavaScript di dalam PDF bawaan Firefox demi keamanan
            "dom.disable_window_move_resize" = lock-true; # Blokir situs web mengubah ukuran atau memindahkan jendela browser
            "devtools.debugger.remote-enabled" = lock-false; # Matikan remote debugging demi keamanan lokal
            "extensions.enabledScopes" = lock 5; # Batasi direktori instalasi ekstensi hanya dari profil pengguna (cegah instalasi siluman)
            "app.shield.optoutstudies.enabled" = lock-false; # Matikan partisipasi dalam studi/uji coba Firefox Shield
            "nimbus.rollouts.enabled" = lock-false; # Matikan eksperimen rollout fitur otomatis Mozilla
          };
        };

        profiles = {
          ${userName} = {
            isDefault = true;
            id = 0;
            inherit bookmarks userChrome;
            extensions.packages =
              (with inputs.firefox-addons.packages.${pkgs.system}; [
                ublock-origin
                multi-account-containers
                bitwarden
                enhanced-h264ify
                simple-tab-groups
                darkreader
                auto-tab-discard
                metamask
              ])
              ++ [
                keplr
                catppuccin-mocha-blue
                video-downloadhelper
              ];
            settings = baseSettings // {
              "privacy.resistFingerprinting" = false;
              "privacy.fingerprintingProtection" = true;
              "privacy.fingerprintingProtection.overrides" = "+AllTargets,-CSSPrefersColorScheme";
              "privacy.clearOnShutdown_v2.cookiesAndStorage" = false;
              "media.peerconnection.enabled" = true;
              "webgl.disabled" = false;
              "geo.enabled" = true;
            };
          };
          "${userName}-hardened" = {
            isDefault = false;
            id = 1;
            inherit bookmarks userChrome;
            extensions.packages =
              (with inputs.firefox-addons.packages.${pkgs.system}; [
                ublock-origin
                bitwarden
                privacy-badger
                canvasblocker
                clearurls
                localcdn
                user-agent-string-switcher
                proton-vpn
                darkreader
                auto-tab-discard
                simple-tab-groups
              ])
              ++ [
                video-downloadhelper
              ];
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
