{
  config,
  selfLib,
  pkgs,
  inputs,
  lib,
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
    geckoExtPath
    mkBookmarkPoliciesTemplate
    mkBookmarkSecret
    lock-false
    lock-true
    lock-empty-string
    lock
    ;

  # Clean list of extension packages (shared between nixosConfig and hmConfig)
  extensionsList = [
    addons.ublock-origin
    addons.bitwarden
    tampermonkey
    addons.auto-tab-discard
    addons.metamask
    addons.container-proxy
    addons.proton-pass
    keplr
    solflare-wallet
  ];

  # Shared policies for Zen (used by both nixosConfig SOPS template and hmConfig)
  zenBrowserPolicies = commonPrivacyPolicies // {
    SearchEngines = commonSearchEngines;
  };
in
selfLib.mkModule {
  name = "apps.browsers.zen";
  description = "Zen Browser Flatpak configuration with dedicated profile directory";

  nixosConfig = {
    environment.etc."zen/policies/policies.json".source =
      config.sops.templates."zen-policies.json".path;

    sops.secrets."zen-bookmarks" = mkBookmarkSecret (selfLib.secretBinary "browsers/zen-bookmarks.enc");
    sops.templates."zen-policies.json" = mkBookmarkPoliciesTemplate {
      ownerName = config.my.user.name;
      basePolicies = zenBrowserPolicies;
      bookmarkPlaceholder = config.sops.placeholder."zen-bookmarks";
    };
  };

  flatpakCfg = {
    "app.zen_browser.zen" = {
      enable = true;
      binName = "zen";

      overrides = {
        Context = {
          filesystems = [
            "/run/opengl-driver/lib/dri:ro"
            "xdg-run/psd"
            "xdg-run/zen"
            "/home/${config.my.user.name}/.config/zen:ro"
          ];
        };
        Environment = {
          LD_PRELOAD = "${pkgs.libva.out}/lib/libva.so.2:${pkgs.libva.out}/lib/libva-drm.so.2";
          LIBVA_DRIVERS_PATH = "/run/opengl-driver/lib/dri";
          LIBVA_DRIVER_NAME = "i965";
          MOZ_ENABLE_WAYLAND = "1";
          MOZ_LEGACY_PROFILES = "1";
          MOZ_SYSTEM_CONFIG_DIR = "/home/${config.my.user.name}/.config/zen";
        };
      };

      symlinks = [
        {
          host = ".config/zen/${config.my.user.name}";
          guest = ".zen/${config.my.user.name}";
        }
      ];
    };
  };

  hmConfig =
    hmOpts:
    let
      zenPolicies = import ./policies.nix {
        inherit
          lock
          lock-true
          lock-false
          lock-empty-string
          ;
      };

      toUserJs =
        prefs:
        lib.concatStringsSep "\n" (
          lib.mapAttrsToList
            (
              name: value:
              let
                realValue = if (builtins.isAttrs value && value ? Value) then value.Value else value;
                valStr =
                  if builtins.isBool realValue then
                    (if realValue then "true" else "false")
                  else if builtins.isInt realValue then
                    toString realValue
                  else
                    ''"${realValue}"'';
              in
              "user_pref(\"${name}\", ${valStr});"
            )
            (
              prefs
              // {
                "extensions.autoDisableScopes" = 0;
                "extensions.enabledScopes" = 15;
              }
            )
        );

      profileName = hmOpts.config.home.username;

      extensionFiles = lib.listToAttrs (
        lib.flatten (
          map (
            addon:
            let
              extId = addon.addonId or (addon.passthru.addonId or null);
            in
            if extId != null then
              [
                (lib.nameValuePair ".config/zen/${profileName}/extensions/${extId}.xpi" {
                  source = "${addon}${geckoExtPath}/${extId}.xpi";
                })
              ]
            else
              [ ]
          ) extensionsList
        )
      );
    in
    {
      home.sessionVariables = {
        MOZ_LEGACY_PROFILES = "1";
      };

      home.file = extensionFiles // {
        ".config/zen/${profileName}/user.js".text = toUserJs zenPolicies;
      };
    };
}
