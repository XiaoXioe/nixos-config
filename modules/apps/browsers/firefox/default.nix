{
  config,
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
    commonPrivacyPolicies
    commonSearchEngines
    mkBookmarkPoliciesTemplate
    mkBookmarkSecret
    ;

  # Extension packages per profile (100% declarative Home Manager packages)
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
      proton-pass
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

  # Single source of truth: policies used by both nixosConfig (/etc) and hmConfig (programs.firefox)
  firefoxPolicies = commonPrivacyPolicies // {
    SearchEngines = commonSearchEngines;
  };

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
          "xdg-run/firefox" # Runtime per-user policy directory
          "xdg-run/org.mozilla.firefox"
        ];
        Environment = {
          LD_PRELOAD = "${pkgs.libva.out}/lib/libva.so.2:${pkgs.libva.out}/lib/libva-drm.so.2";
          LIBVA_DRIVERS_PATH = "/run/opengl-driver/lib/dri";
          MOZ_LEGACY_PROFILES = "1";
          MOZ_SYSTEM_CONFIG_DIR = "/home/${config.my.user.name}/.config/mozilla/firefox";
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
    environment.etc."firefox/policies/policies.json".source =
      config.sops.templates."firefox-policies.json".path;

    sops.secrets."firefox-bookmarks" = mkBookmarkSecret (selfLib.secretBinary "firefox-bookmarks.enc");
    sops.templates."firefox-policies.json" = mkBookmarkPoliciesTemplate {
      ownerName = config.my.user.name;
      basePolicies = firefoxPolicies;
      bookmarkPlaceholder = config.sops.placeholder."firefox-bookmarks";
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
        "toolkit.policies.perUserDir" = true;
        "extensions.autoDisableScopes" = 0;
        "extensions.enabledScopes" = 15;
      };

      userChrome = ''
        .tab-close-button { display: none !important; }
      '';
    in
    {
      home.sessionVariables = {
        MOZ_LEGACY_PROFILES = "1";
      };

      programs.firefox = {
        configPath = "${hmOpts.config.xdg.configHome}/mozilla/firefox";
        enable = true;
        languagePacks = [
          "en-US"
          "id"
        ];
        policies = firefoxPolicies;

        profiles = {
          ${hmOpts.config.home.username} = {
            isDefault = true;
            id = 0;
            inherit userChrome;
            extensions.packages = defaultProfileExtensions;
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
            inherit userChrome;
            extensions.packages = hardenedProfileExtensions;
            settings = baseSettings // {
              "privacy.resistFingerprinting" = false;
              "privacy.fingerprintingProtection" = true;
              "privacy.clearOnShutdown_v2.cookiesAndStorage" = false;
              "privacy.clearOnShutdown_v2.cache" = false;
              "privacy.sanitize.sanitizeOnShutdown" = false;
              "privacy.clearOnShutdown_v2.historyFormDataAndDownloads" = false;
              "privacy.clearOnShutdown_v2.browsingHistoryAndDownloads" = false;
              "media.peerconnection.enabled" = false;
              "webgl.disabled" = false;
              "geo.enabled" = false;
              "browser.privatebrowsing.autostart" = false;
              "device.sensors.enabled" = false;
            };
          };
        };
      };
    };
}
