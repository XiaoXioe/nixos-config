{
  pkgs,
  selfLib,
  inputs,
  ...
}:
let
  inherit (selfLib.browserAddons { inherit pkgs inputs; })
    addons
    tampermonkey
    keplr
    solflare-wallet
    mkExtensionSettings
    ;

  # Import separated data files
  bookmarksList = import ./bookmarks.nix;
in
selfLib.mkModule {
  name = "apps.browsers.firefox";
  description = "Firefox configuration for user";

  flatpakCfg = {
    "org.mozilla.firefox" = {
      enable = true;
      overrides = {
        Context.filesystems = [
          "/run/opengl-driver/lib/dri:ro"
          "xdg-run/psd" # Profile Sync Daemon tmpfs
        ];
        Environment = {
          LD_PRELOAD = "${pkgs.libva.out}/lib/libva.so.2:${pkgs.libva.out}/lib/libva-drm.so.2";
          LIBVA_DRIVERS_PATH = "/run/opengl-driver/lib/dri";
          MOZ_LEGACY_PROFILES = "1";
        };
      };
      symlinks = [
        {
          host = ".config/mozilla/firefox";
          guest = ".mozilla/firefox";
        }
      ];
      nativePkgs = pkgs.firefox;
      hmProgram = {
        name = "firefox";
      };
    };
  };

  nixosConfig = {
    environment.sessionVariables = {
      MOZ_ENABLE_WAYLAND = "1";
    };
  };

  hmConfig =
    hmOpts:
    let
      lib = hmOpts.lib;

      # Extension packages per profile
      defaultProfileExtensions =
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

      hardenedProfileExtensions = with addons; [
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
      ];

      allFirefoxExtensions = lib.unique (defaultProfileExtensions ++ hardenedProfileExtensions);

      # Native Home Manager extension environments via buildEnv
      defaultExtensionsEnv = pkgs.buildEnv {
        name = "firefox-default-extensions";
        paths = defaultProfileExtensions;
        pathsToLink = [ "/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}" ];
      };

      hardenedExtensionsEnv = pkgs.buildEnv {
        name = "firefox-hardened-extensions";
        paths = hardenedProfileExtensions;
        pathsToLink = [ "/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}" ];
      };

      # Common enterprise policies for both Native and Flatpak Firefox
      commonPolicies = {
        ExtensionSettings = mkExtensionSettings allFirefoxExtensions;
        DisableTelemetry = true;
        SearchSuggestEnabled = false;
        DisableFirefoxStudies = true;
        PasswordManagerEnabled = false;
        DisableFirefoxAccounts = true;
        DontCheckDefaultBrowser = true;
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
      home.sessionVariables = {
        MOZ_LEGACY_PROFILES = "1";
      };

      home.activation.prepareFirefoxProfiles = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
        # Hapus file backup lama agar tidak memicu error clobber
        ${pkgs.coreutils}/bin/rm -f "$HOME/.config/mozilla/firefox/profiles.ini.hm-bak"

        # Hapus profiles.ini jika berupa file biasa (bukan symlink) agar linkGeneration bisa membuat symlink baru tanpa backup
        if [ -f "$HOME/.config/mozilla/firefox/profiles.ini" ] && [ ! -L "$HOME/.config/mozilla/firefox/profiles.ini" ]; then
          ${pkgs.coreutils}/bin/rm -f "$HOME/.config/mozilla/firefox/profiles.ini"
        fi

        # Penanganan dangling atau invalid symlink (seperti /dev/null atau /run/user/...) akibat Profile Sync Daemon (PSD) saat boot
        if [ -d "$HOME/.config/mozilla/firefox" ]; then
          for prof in "$HOME/.config/mozilla/firefox/"*; do
            if [ -L "$prof" ]; then
              target=$(${pkgs.coreutils}/bin/readlink "$prof" || true)
              if [ ! -e "$prof" ] || [ "$target" = "/dev/null" ] || [[ "$target" == /run/user/* ]]; then
                backup="''${prof}-backup"
                if [ -d "$backup" ]; then
                  echo "PSD cleanup: restoring $(${pkgs.coreutils}/bin/basename "$prof") from backup"
                  ${pkgs.coreutils}/bin/rm -f "$prof"
                  ${pkgs.coreutils}/bin/mv "$backup" "$prof"
                else
                  echo "PSD cleanup: removing invalid symlink $(${pkgs.coreutils}/bin/basename "$prof")"
                  ${pkgs.coreutils}/bin/rm -f "$prof"
                fi
              fi
            fi
          done
        fi
      '';

      home.activation.copyFirefoxProfiles = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        if [ -L "$HOME/.config/mozilla/firefox/profiles.ini" ]; then
          real_file=$(${pkgs.coreutils}/bin/readlink -f "$HOME/.config/mozilla/firefox/profiles.ini")
          ${pkgs.coreutils}/bin/rm -f "$HOME/.config/mozilla/firefox/profiles.ini"
          ${pkgs.coreutils}/bin/cp "$real_file" "$HOME/.config/mozilla/firefox/profiles.ini"
          ${pkgs.coreutils}/bin/chmod 644 "$HOME/.config/mozilla/firefox/profiles.ini"

          # Reset Default di section [Install] ke 'default'
          ${pkgs.gnused}/bin/sed -i '/^\[Install\]/,/^\[/s/^Default=.*/Default=default/' "$HOME/.config/mozilla/firefox/profiles.ini"
        fi
      '';

      home.file = {
        # Declarative per-profile extension directories linked via Home Manager buildEnv
        ".config/mozilla/firefox/${hmOpts.config.home.username}/extensions" = {
          source = "${defaultExtensionsEnv}/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}";
        };
        ".config/mozilla/firefox/${hmOpts.config.home.username}-hardened/extensions" = {
          source = "${hardenedExtensionsEnv}/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}";
        };

        # Flatpak systemconfig extension policies for org.mozilla.firefox
        ".local/share/flatpak/extension/org.mozilla.firefox.systemconfig/x86_64/stable/policies/policies.json".text =
          builtins.toJSON {
            policies = commonPolicies;
          };
      };

      programs.firefox = {
        configPath = "${hmOpts.config.xdg.configHome}/mozilla/firefox";
        enable = true;
        languagePacks = [
          "en-US"
          "id"
        ];
        policies = commonPolicies // {
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
        };

        profiles = {
          ${hmOpts.config.home.username} = {
            isDefault = true;
            id = 0;
            inherit bookmarks userChrome;
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
