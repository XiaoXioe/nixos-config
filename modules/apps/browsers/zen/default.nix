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
    resolveAddons
    lock-false
    lock-true
    lock
    ;

  zenPolicies = import ./_policies {
    inherit
      lock
      lock-true
      lock-false
      ;
  };

  zenBrowserPolicies = lib.recursiveUpdate commonPrivacyPolicies {
    SearchEngines = commonSearchEngines;
    Certificates = {
      ImportEnterpriseRoots = true;
    };
    OverrideFirstRunPage = "";
    OverridePostUpdatePage = "";
    Preferences = zenPolicies;
  };
in
selfLib.mkModule {
  name = "apps.browsers.zen";
  description = "Zen Browser configuration powered by zen-browser-flake";

  nixosConfig = {
    my.services.vmtouch.paths = [
      inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

    environment.sessionVariables = {
      MOZ_ENABLE_WAYLAND = "1";
    };

    sops.secrets = {
      "zen-bookmarks" = mkBookmarkSecret ./zen-bookmarks.enc;
    };

    sops.templates = {
      "zen-policies.json" = mkBookmarkPoliciesTemplate {
        ownerName = config.my.user.name;
        basePolicies = zenBrowserPolicies;
        bookmarkPlaceholder = config.sops.placeholder."zen-bookmarks";
      };
    };

    environment.etc = {
      "zen/policies/policies.json".source = config.sops.templates."zen-policies.json".path;
    };
  };

  hmConfig =
    hmOpts:
    let
      user = hmOpts.config.home.username;
      common = import ./profiles/common.nix { inherit lib; };

      baseSettings = {
        "accessibility.force_disabled" = 1;
        "browser.urlbar.quickactions.enabled" = false;
        "browser.disableResetPrompt" = true;
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        # Zen Specific Preferences
        "zen.workspaces.continue-where-left-off" = true;
        "zen.welcome-screen.seen" = true;
        "zen.view.compact.hide-tabbar" = true;
        "zen.view.compact.hide-toolbar" = true;
        "zen.view.compact.animate-sidebar" = true;
        "zen.urlbar.behavior" = "float";
        "zen.workspaces.natural-scroll" = true;
        "zen.release-notes.show" = false;
        "zen.release-notes.show-on-update" = false;
        "zen.watermark.enabled" = false;
        "zen.theme.content-element-separation" = 0;
        "zen.widget.linux.transparency" = false;
        "zen.view.sidebar-collapsed.hide-mute-button" = true;
        "zen.theme.essentials-favicon-bg" = true;
        "zen.ui.migration.compact-mode-button-added" = true;
        "zen.view.compact.enable-at-startup" = true;
        "zen.view.use-single-toolbar" = false;
        "zen.tab-unloader.enabled" = true;
        "browser.tabs.unloadOnLowMemory" = true;
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
          ${user} = import ./profiles/primary.nix {
            inherit
              baseSettings
              lib
              common
              amoAddons
              resolveAddons
              ;
          };
          "${user}-01" = import ./profiles/profile01.nix {
            inherit
              baseSettings
              lib
              common
              amoAddons
              resolveAddons
              ;
          };
        };
      };
    };
}
