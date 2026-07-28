{
  config,
  pkgs,
  inputs,
  lib,
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

  defaultProfileExtensions =
    (with addons; [
      ublock-origin
      bitwarden
      multi-account-containers
      auto-tab-discard
      proton-pass
      tampermonkey
    ])
    ++ [
      keplr
      solflare-wallet
    ];

  zenBrowserPolicies = lib.recursiveUpdate commonPrivacyPolicies {
    SearchEngines = commonSearchEngines;
  };
in
selfLib.mkModule {
  name = "apps.browsers.zen";
  description = "Zen Browser configuration powered by zen-browser-flake";

  nixosConfig = {
    environment.sessionVariables = {
      MOZ_ENABLE_WAYLAND = "1";
    };

    sops.secrets = {
      "zen-bookmarks" = mkBookmarkSecret (selfLib.secretBinary "browsers/zen-bookmarks.enc");
    };

    sops.templates = {
      "zen-policies.json" = mkBookmarkPoliciesTemplate {
        ownerName = config.my.user.name;
        basePolicies = zenBrowserPolicies;
        bookmarkPlaceholder = config.sops.placeholder."zen-bookmarks";
      };
    };

    environment.etc = {
      "zen/policies/policies.json".text = builtins.toJSON { policies = zenBrowserPolicies; };
    };
  };

  hmConfig =
    hmOpts:
    let
      user = hmOpts.config.home.username;

      zenPolicies = import ./policies {
        inherit
          lock
          lock-true
          lock-false
          lock-empty-string
          ;
      };

      baseSettings = zenPolicies // {
        "browser.startup.page" = 3;
        "accessibility.force_disabled" = 1;
        "browser.urlbar.quickactions.enabled" = false;
        "widget.dmabuf.force-enabled" = true;
        "browser.disableResetPrompt" = true;
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "toolkit.policies.perUserDir" = false;
        "extensions.autoDisableScopes" = 0;
        "extensions.enabledScopes" = 15;
      };
    in
    {
      imports = [
        inputs.zen-browser.homeModules.default
      ];

      programs.zen-browser = {
        enable = true;
        setAsDefaultBrowser = true;
        package = inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default;
        policies = zenBrowserPolicies;

        profiles = {
          ${user} = {
            isDefault = true;
            id = 0;
            extensions.packages = defaultProfileExtensions;
            settings = baseSettings;
          };
        };
      };
    };
}
