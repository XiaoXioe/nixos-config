{
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

      # VA-API hardware video decoding: the Flatpak GL extension only bundles Mesa's
      # built-in VAAPI drivers (radeonsi, nouveau, etc.) but NOT the separate
      # intel-vaapi-driver (i965) needed for Ivy Bridge. Mount the host's graphics
      # driver directory and point libva to it.
      overrides = {
        Context = {
          filesystems = [
            "/run/opengl-driver/lib/dri:ro" # Host's VA-API drivers (i965, iHD)
          ];
        };
        Environment = {
          LD_PRELOAD = "${pkgs.libva.out}/lib/libva.so.2:${pkgs.libva.out}/lib/libva-drm.so.2";
          LIBVA_DRIVERS_PATH = "/run/opengl-driver/lib/dri"; # Tell libva where to find i965_drv_video.so
          LIBVA_DRIVER_NAME = "i965"; # Intel Ivy Bridge VA-API driver
          MOZ_DISABLE_RDD_SANDBOX = "1"; # Allow RDD process to access /dev/dri for VA-API
          MOZ_ENABLE_WAYLAND = "1"; # Ensure Wayland backend for DMABUF/VA-API
        };
      };

      # Symlink only the profile subdirectory inside .zen to bypass Flatpak's sandbox escape restriction on root dotfiles
      symlinks = [
        {
          host = ".config/zen/klein-moretti";
          guest = ".zen/klein-moretti";
        }
      ];
    };
  };

  hmConfig =
    hmOpts:
    let
      addons = inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system};

      # Helper for building custom addons
      buildAmoAddon =
        {
          pname,
          addonId,
          sha256,
          slug ? pname,
          version ? "latest",
        }:
        pkgs.stdenv.mkDerivation {
          name = "${pname}-${version}";
          src = pkgs.fetchurl {
            url = "https://addons.mozilla.org/firefox/downloads/latest/${slug}/latest.xpi";
            inherit sha256;
          };
          preferLocalBuild = true;
          allowSubstitutes = false;
          buildCommand = ''
            dst="$out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}"
            mkdir -p "$dst"
            ln -s "$src" "$dst/${addonId}.xpi"
          '';
        };

      keplr = buildAmoAddon {
        pname = "keplr";
        addonId = "keplr-extension@keplr.app";
        sha256 = "166ggld6b4lh1hvsm2bd0g8b7kp7y9ln2fhf7jfcmx0pbd9z4zzp";
      };

      solflare-wallet = buildAmoAddon {
        pname = "solflare-wallet";
        addonId = "{6d72262a-b243-4dc6-8f4f-be96c74e0a86}";
        sha256 = "sha256-740OObxZUapauVbaESJMY1nt0F5tiNEaK32CGiMFgSA=";
      };

      tampermonkey = addons.tampermonkey.overrideAttrs (old: {
        meta = (old.meta or { }) // {
          license = [ ];
        };
      });

      lock-false = {
        Value = false;
        Status = "locked";
      };
      lock-true = {
        Value = true;
        Status = "locked";
      };
      lock-empty-string = {
        Value = "";
        Status = "locked";
      };
      lock = value: {
        Value = value;
        Status = "locked";
      };

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

      # Declarative extensions list for modular mapping (DRY)
      extensionsList = [
        {
          name = "uBlock0@raymondhill.net";
          pkg = addons.ublock-origin;
        }
        {
          name = "{446900e4-71c2-419f-a6a7-df9c091e268b}";
          pkg = addons.bitwarden;
        }
        {
          name = "firefox@tampermonkey.net";
          pkg = tampermonkey;
        }
        {
          name = "simple-tab-groups@drive4ik";
          pkg = addons.simple-tab-groups;
        }
        {
          name = "{c2c003ee-bd69-42a2-b0e9-6f34222cb046}";
          pkg = addons.auto-tab-discard;
        }
        {
          name = "webextension@metamask.io";
          pkg = addons.metamask;
        }
        {
          name = "contaner-proxy@bekh-ivanov.me";
          pkg = addons.container-proxy;
        }
        {
          name = "keplr-extension@keplr.app";
          pkg = keplr;
        }
        {
          name = "{6d72262a-b243-4dc6-8f4f-be96c74e0a86}";
          pkg = solflare-wallet;
        }
      ];

      # Dynamically map the extensions list into Home Manager file configurations
      extensionsConfig = builtins.listToAttrs (
        map (ext: {
          name = ".config/zen/${profileName}/extensions/${ext.name}.xpi";
          value = {
            source = "${ext.pkg}/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/${ext.name}.xpi";
          };
        }) extensionsList
      );
    in
    {
      # Clean up old real .zen directory once to avoid conflicts with our profiles.ini setup
      home.activation.cleanLegacyZen = hmOpts.lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
        if [ -d "$HOME/.var/app/app.zen_browser.zen/.zen" ] && [ ! -L "$HOME/.var/app/app.zen_browser.zen/.zen" ]; then
          rm -rf "$HOME/.var/app/app.zen_browser.zen/.zen"
        fi
      '';

      # Write profiles.ini as a physical, writeable file rather than a read-only Nix store symlink.
      # Gecko browsers (Firefox/Zen) require write access to profiles.ini on startup and will revert
      # to creating a random profile if the file is write-locked.
      home.activation.writeZenProfiles = hmOpts.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p "$HOME/.var/app/app.zen_browser.zen/.zen"
        cat << 'EOF' > "$HOME/.var/app/app.zen_browser.zen/.zen/profiles.ini"
        [General]
        StartWithLastProfile=1
        Version=2

        [Profile0]
        Name=${profileName}
        IsRelative=1
        Path=${profileName}
        Default=1
        EOF
        chmod 644 "$HOME/.var/app/app.zen_browser.zen/.zen/profiles.ini"
      '';

      home.file = {
        # Store user.js and extensions in the persisted host directory (~/.config/zen/...)
        ".config/zen/${profileName}/user.js".text = toUserJs zenPolicies;

        # System policies for Zen Flatpak using the official systemconfig extension
        ".local/share/flatpak/extension/app.zen_browser.zen.systemconfig/x86_64/stable/policies/policies.json".text =
          builtins.toJSON {
            policies = {
              Preferences = lib.filterAttrs (
                name: value: builtins.isAttrs value && value ? Status && value.Status == "locked"
              ) zenPolicies;

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
      }
      // extensionsConfig;
    };
}
