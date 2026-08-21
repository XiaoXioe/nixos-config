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

  # Instansiasi Zen Browser langsung menggunakan `pkgs` lokal.
  # Diperlukan agar zen-browser-flake mengonsumsi overlay `pkgs` sistem (seperti kompatibilitas ffmpeg_9 di bawah).
  zenPackage = (import "${inputs.zen-browser}/default.nix" { inherit pkgs; }).default;
in
selfLib.mkModule {
  name = "apps.browsers.zen";
  description = "Zen Browser configuration powered by zen-browser-flake";

  nixosConfig = {
    # Upstream `zen-browser-flake` memerlukan dependensi `ffmpeg_9`.
    # Karena sistem menggunakan channel stable (nixos-26.05) dengan `inputs.nixpkgs.follows = "nixpkgs"`,
    # petakan `ffmpeg_9` ke `ffmpeg_7` / `ffmpeg` bawaan 26.05 agar evaluasi flake tidak error.
    nixpkgs.overlays = [
      (_final: prev: {
        ffmpeg_9 = prev.ffmpeg_7 or prev.ffmpeg;
      })
    ];

    my.services.vmtouch.paths = [
      zenPackage
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
        package = zenPackage;
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
