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
    mkExtensionSettings
    commonPrivacyPolicies
    commonSearchEngines
    geckoExtPath
    mkCopyPoliciesScript
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
    keplr
    solflare-wallet
  ];

  # Shared policies for Zen (used by both nixosConfig SOPS template and hmConfig)
  zenBrowserPolicies = commonPrivacyPolicies // {
    ExtensionSettings = mkExtensionSettings extensionsList;
    SearchEngines = commonSearchEngines;
  };
in
selfLib.mkModule {
  name = "apps.browsers.zen";
  description = "Zen Browser Flatpak configuration with dedicated profile directory";

  nixosConfig = {
    environment.etc."zen/policies/policies.json".source =
      config.sops.templates."zen-policies.json".path;

    sops.secrets."zen-bookmarks" = mkBookmarkSecret (selfLib.secretBinary "zen-bookmarks.enc");
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

      # VA-API hardware video decoding: the Flatpak GL extension only bundles Mesa's
      # built-in VAAPI drivers (radeonsi, nouveau, etc.) but NOT the separate
      # intel-vaapi-driver (i965) needed for Ivy Bridge. Mount the host's graphics
      # driver directory and point libva to it.
      overrides = {
        Context = {
          filesystems = [
            "/run/opengl-driver/lib/dri:ro" # Host's VA-API drivers (i965, iHD)
            "xdg-run/psd" # Profile Sync Daemon tmpfs
          ];
        };
        Environment = {
          LD_PRELOAD = "${pkgs.libva.out}/lib/libva.so.2:${pkgs.libva.out}/lib/libva-drm.so.2";
          LIBVA_DRIVERS_PATH = "/run/opengl-driver/lib/dri"; # Tell libva where to find i965_drv_video.so
          LIBVA_DRIVER_NAME = "i965"; # Intel Ivy Bridge VA-API driver
          MOZ_ENABLE_WAYLAND = "1"; # Ensure Wayland backend for DMABUF/VA-API
          MOZ_LEGACY_PROFILES = "1";
        };
      };

      # Symlink only the profile subdirectory inside .zen to bypass Flatpak's sandbox escape restriction on root dotfiles
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
      # Import Zen-specific policies from local policies.nix (modular)
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
          lib.mapAttrsToList (
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
          ) prefs
        );

      profileName = hmOpts.config.home.username;

      extensionsEnv = pkgs.buildEnv {
        name = "zen-extensions";
        paths = extensionsList;
        pathsToLink = [ geckoExtPath ];
      };
    in
    {
      home.sessionVariables = {
        MOZ_LEGACY_PROFILES = "1";
      };

      # Write profiles.ini as a physical, writeable file rather than a read-only Nix store symlink.
      # Gecko browsers (Firefox/Zen) require write access to profiles.ini on startup and will revert
      # to creating a random profile if the file is write-locked.
      home.activation.writeZenProfiles = hmOpts.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${pkgs.coreutils}/bin/mkdir -p "$HOME/.var/app/app.zen_browser.zen/.zen" "$HOME/.var/app/app.zen_browser.zen/config/zen"
        if [ -d "$HOME/.config/zen/${profileName}" ]; then
          ${pkgs.coreutils}/bin/chmod 700 "$HOME/.config/zen/${profileName}"
        fi
        ${pkgs.coreutils}/bin/ln -sfn "$HOME/.config/zen/${profileName}" "$HOME/.var/app/app.zen_browser.zen/config/zen/${profileName}"
        ${pkgs.coreutils}/bin/ln -sfn "$HOME/.config/zen/${profileName}" "$HOME/.var/app/app.zen_browser.zen/.zen/${profileName}"
        ${pkgs.coreutils}/bin/cat << 'EOF' > "$HOME/.var/app/app.zen_browser.zen/.zen/profiles.ini"
        [General]
        StartWithLastProfile=1
        Version=2

        [Profile0]
        Name=${profileName}
        IsRelative=1
        Path=${profileName}
        Default=1
        EOF
        ${pkgs.coreutils}/bin/cp "$HOME/.var/app/app.zen_browser.zen/.zen/profiles.ini" "$HOME/.var/app/app.zen_browser.zen/config/zen/profiles.ini"
        ${pkgs.coreutils}/bin/chmod 644 "$HOME/.var/app/app.zen_browser.zen/.zen/profiles.ini" "$HOME/.var/app/app.zen_browser.zen/config/zen/profiles.ini"
        ${pkgs.coreutils}/bin/rm -f "$HOME/.var/app/app.zen_browser.zen/config/zen/installs.ini" "$HOME/.var/app/app.zen_browser.zen/.zen/installs.ini"
      '';

      home.activation.copyZenPolicies =
        hmOpts.config.lib.dag.entryAfter [ "writeBoundary" ]
          (mkCopyPoliciesScript {
            etcPath = "/etc/zen/policies/policies.json";
            destinations = [
              "$HOME/.config/zen/distribution"
              "$HOME/.var/app/app.zen_browser.zen/config/zen/distribution"
              "$HOME/.var/app/app.zen_browser.zen/.zen/distribution"
            ];
          });

      home.file = {

        # Store user.js and extensions in the persisted host directory (~/.config/zen/...)
        ".config/zen/${profileName}/user.js".text = toUserJs zenPolicies;

        # Declarative extensions (dynamically linked using buildEnv)
        ".config/zen/${profileName}/extensions" = {
          source = "${extensionsEnv}${geckoExtPath}";
          recursive = true;
        };
      };
    };
}
