{
  config,
  pkgs,
  inputs,
  selfLib,
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
    lock-false
    lock-true
    lock-empty-string
    lock
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
      binName = "firefox";

      overrides = {
        Context = {
          filesystems = [
            "/run/opengl-driver/lib/dri:ro"
            "xdg-run/psd" # Profile Sync Daemon tmpfs
            "xdg-run/firefox" # Runtime per-user policy directory
            "xdg-run/org.mozilla.firefox"
          ];
        };
        Environment = {
          LD_PRELOAD = "${pkgs.libva.out}/lib/libva.so.2:${pkgs.libva.out}/lib/libva-drm.so.2";
          LIBVA_DRIVERS_PATH = "/run/opengl-driver/lib/dri";
          MOZ_LEGACY_PROFILES = "1";
          MOZ_SYSTEM_CONFIG_DIR = "~/.config/mozilla/firefox";
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

    sops.secrets = {
      "firefox-bookmarks" = mkBookmarkSecret (selfLib.secretBinary "browsers/firefox-bookmarks.enc");
    };

    sops.templates = {
      "firefox-policies.json" = mkBookmarkPoliciesTemplate {
        ownerName = config.my.user.name;
        basePolicies = firefoxPolicies;
        bookmarkPlaceholder = config.sops.placeholder."firefox-bookmarks";
      };
    };
  };

  hmConfig =
    hmOpts:
    let
      firefoxPoliciesPrefs = import ./policies {
        inherit
          lock
          lock-true
          lock-false
          lock-empty-string
          ;
      };

      baseSettings = firefoxPoliciesPrefs // {
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

        profiles = {
          default = {
            id = 0;
            name = "Default User";
            isDefault = true;
            settings = baseSettings;
            userChrome = userChrome;
            extensions.packages = defaultProfileExtensions;
          };

          hardened = {
            id = 1;
            name = "Hardened User";
            isDefault = false;
            settings = baseSettings // {
              "privacy.firstparty.isolate" = true;
              "privacy.trackingprotection.fingerprinting.enabled" = true;
              "privacy.trackingprotection.cryptomining.enabled" = true;
              "dom.event.clipboardevents.enabled" = false;
              "media.peerconnection.enabled" = false;
            };
            userChrome = userChrome;
            extensions.packages = hardenedProfileExtensions;
          };
        };
      };

      # Syarat Mozilla Gecko Policy: File policies.json di-link ke folder per-user
      # ~/.config/mozilla/firefox/policies/policies.json
      home.file = selfLib.mkHmSymlinks hmOpts.config {
        ".config/mozilla/firefox/policies/policies.json" =
          config.sops.templates."firefox-policies.json".path;
      };
    };
}
