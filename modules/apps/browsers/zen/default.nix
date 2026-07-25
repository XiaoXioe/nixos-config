{
  config,
  selfLib,
  pkgs,
  inputs,
  lib,
  ...
}:

selfLib.mkModule {
  name = "apps.browsers.zen";
  description = "Zen Browser Flatpak configuration with dedicated profile directory";

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
          MOZ_DISABLE_RDD_SANDBOX = "1"; # Allow RDD process to access /dev/dri for VA-API
          MOZ_DISABLE_CONTENT_SANDBOX = "1"; # Prevent tab process clone() EPERM crashes inside Flatpak
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
      inherit (selfLib.browserAddons { inherit pkgs inputs; })
        lock-false
        lock-true
        lock-empty-string
        lock
        addons
        tampermonkey
        keplr
        solflare-wallet
        mkExtensionSettings
        ;

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

      # Clean list of extension packages (same as Firefox)
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

      extensionsEnv = pkgs.buildEnv {
        name = "zen-extensions";
        paths = extensionsList;
        pathsToLink = [ "/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}" ];
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
        ${pkgs.coreutils}/bin/rm -f "$HOME/.config/zen/${profileName}/extensions.json" "$HOME/.config/zen/${profileName}/addonStartup.json.lz4"
        ${pkgs.coreutils}/bin/rm -f "$HOME/.var/app/app.zen_browser.zen/config/zen/installs.ini" "$HOME/.var/app/app.zen_browser.zen/.zen/installs.ini"
      '';

      home.file = {
        # Store user.js and extensions in the persisted host directory (~/.config/zen/...)
        ".config/zen/${profileName}/user.js".text = toUserJs zenPolicies;

        # Declarative extensions (dynamically linked using buildEnv)
        ".config/zen/${profileName}/extensions" = {
          source = "${extensionsEnv}/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}";
          recursive = true;
        };

        # System policies for Zen Flatpak using the official systemconfig extension
        ".local/share/flatpak/extension/app.zen_browser.zen.systemconfig/x86_64/stable/policies/policies.json".text =
          builtins.toJSON {
            policies = {
              ExtensionSettings = mkExtensionSettings extensionsList;

              DisableFirefoxAccounts = true;
              DisableTelemetry = true;
              SearchSuggestEnabled = false;
              DisableFirefoxStudies = true;
              PasswordManagerEnabled = false;
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
              SearchEngines = {
                Remove = [
                  "google"
                  "Google"
                  "ebay"
                  "eBay"
                  "bing"
                  "Bing"
                  "ecosia"
                  "Ecosia"
                  "wikipedia"
                  "Wikipedia"
                  "perplexity"
                  "Perplexity"
                  "amazondotcom-us"
                  "Amazon.com"
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
          };
      };
    };
}
