{
  config,
  pkgs,
  inputs,
  lib,
  selfLib,
  ...
}:

let
  inherit (selfLib.browserAddonsFor { inherit pkgs inputs; })
    amoAddons
    commonPrivacyPolicies
    commonSearchEngines
    mkBookmarkPoliciesTemplate
    mkBookmarkSecret
    mkAmoExtensionSettings
    lock-false
    lock-true
    lock-empty-string
    lock
    ;

  # Extension definitions for remote Mozilla AMO auto-update
  defaultProfileExtensions = with amoAddons; [
    ublock-origin
    multi-account-containers
    bitwarden
    simple-tab-groups
    auto-tab-discard
    metamask
    container-proxy
    tampermonkey
    proton-pass
    keplr
    solflare-wallet
  ];

  hardenedProfileExtensions = with amoAddons; [
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

  firefoxPoliciesPrefs = import ./_policies {
    inherit
      lock
      lock-true
      lock-false
      lock-empty-string
      ;
  };

  firefoxPolicies = lib.recursiveUpdate commonPrivacyPolicies {
    SearchEngines = commonSearchEngines;
    OverrideFirstRunPage = "";
    OverridePostUpdatePage = "";
    ExtensionSettings = mkAmoExtensionSettings (defaultProfileExtensions ++ hardenedProfileExtensions) {
      mode = "force_installed";
    };
    Preferences = firefoxPoliciesPrefs;
  };
in
selfLib.mkModule {
  name = "apps.browsers.firefox";
  description = "Firefox configuration for user";

  preservation = {
    userDirectories = [
      ".cache/mozilla"
    ];
  };

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
      "firefox-bookmarks" = mkBookmarkSecret ./firefox-bookmarks.enc;
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

        profiles = {
          default = {
            id = 0;
            name = "Default User";
            isDefault = true;
            settings = baseSettings;
            inherit userChrome;
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
            inherit userChrome;
          };
        };
      };
    };
}
