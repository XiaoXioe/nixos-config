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

      prefs = {
        # Telemetry
        "datareporting.healthreport.uploadEnabled" = lock-false;
        "datareporting.policy.dataSubmissionEnabled" = lock-false;
        "toolkit.telemetry.enabled" = lock-false;
        "toolkit.telemetry.unified" = lock-false;
        "toolkit.telemetry.server" = lock "data:,";
        "toolkit.telemetry.archive.enabled" = lock-false;
        "experiments.supported" = lock-false;
        "experiments.enabled" = lock-false;
        "experiments.activeExperiment" = lock-false;
        "network.allow-experiments" = lock-false;
        "browser.ping-centre.telemetry" = lock-false;
        "browser.newtabpage.activity-stream.feeds.telemetry" = lock-false;
        "browser.newtabpage.activity-stream.telemetry" = lock-false;

        # Pocket & Ads
        "extensions.pocket.enabled" = lock-false;
        "browser.newtabpage.activity-stream.feeds.section.topstories" = lock-false;
        "browser.newtabpage.activity-stream.section.highlights.includePocket" = lock-false;
        "browser.newtabpage.activity-stream.showSponsored" = lock-false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = lock-false;

        # Recommendations
        "browser.discovery.enabled" = lock-false;
        "extensions.getAddons.showPane" = lock-false;
        "extensions.htmlaboutaddons.recommendations.enabled" = lock-false;
        "browser.urlbar.suggest.searches" = lock-false;
        "browser.urlbar.quicksuggest.enabled" = lock-false;

        # Startup
        "browser.startup.page" = lock 3; # Restore session
        "browser.shell.checkDefaultBrowser" = lock-false;
        "extensions.autoDisableScopes" = lock 0;

        # Onboarding / Welcome Screen
        "zen.welcome-screen.seen" = lock-true;
        "zen.workspaces.continue-where-left-off" = lock-true;
        "browser.aboutwelcome.enabled" = lock-false;
        "browser.onboarding.enabled" = lock-false;
        "trailhead.firstrun.didSeeAboutWelcome" = lock-true;
        "browser.startup.firstrun.bundle" = lock-false;
        "browser.startup.homepage_override.mstone" = lock "ignore";

        # Default Search Engine (First Run)
        "browser.search.defaultenginename" = lock "DuckDuckGo";
        "browser.search.selectedEngine" = lock "DuckDuckGo";
        "browser.urlbar.placeholderName" = lock "DuckDuckGo";
        "browser.urlbar.placeholderName.private" = lock "DuckDuckGo";
        "browser.search.region" = lock "US";

        # Dark Theme
        "ui.systemUsesDarkTheme" = lock 1;
        "layout.css.prefers-color-scheme.content-override" = lock 0; # 0 = Force Dark
        "extensions.activeThemeID" = "firefox-compact-dark@mozilla.org";

        # Zen Browser Specific Preferences
        "zen.watermark.enabled" = lock-false; # Disable splash screen on startup
        "zen.view.compact.hide-toolbar" = lock-true; # Auto-hide toolbar in compact mode
        "zen.theme.content-element-separation" = lock 0; # Set border gap around window to 0 for maximum screen space
        "zen.widget.linux.transparency" = lock-true; # Enable UI transparency support on Linux (Wayland/Niri)
        "zen.view.sidebar-collapsed.hide-mute-button" = lock-true;
        "zen.theme.essentials-favicon-bg" = lock-true;

        # Performance & Graphics
        "widget.dmabuf.force-enabled" = lock-true;
        "webgl.disabled" = lock-false;

        # Privacy
        "extensions.formautofill.addresses.enabled" = lock-false;
        "extensions.formautofill.creditCards.enabled" = lock-false;
        "privacy.resistFingerprinting" = lock-false;
        "privacy.fingerprintingProtection" = lock-true;
        "privacy.fingerprintingProtection.overrides" =
          lock "+AllTargets,-CSSPrefersColorScheme,-ReduceTimerPrecision";
        "privacy.clearOnShutdown_v2.cookiesAndStorage" = lock-false;
        "media.peerconnection.enabled" = lock-true;
        "geo.enabled" = lock-true;
      };

      profileName = hmOpts.config.home.username;
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
        ".config/zen/${profileName}/user.js".text = toUserJs prefs;

        # Declarative extensions
        ".config/zen/${profileName}/extensions/uBlock0@raymondhill.net.xpi".source =
          "${addons.ublock-origin}/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/uBlock0@raymondhill.net.xpi";
        ".config/zen/${profileName}/extensions/{446900e4-71c2-419f-a6a7-df9c091e268b}.xpi".source =
          "${addons.bitwarden}/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/{446900e4-71c2-419f-a6a7-df9c091e268b}.xpi";
        ".config/zen/${profileName}/extensions/firefox@tampermonkey.net.xpi".source =
          "${tampermonkey}/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/firefox@tampermonkey.net.xpi";
        ".config/zen/${profileName}/extensions/simple-tab-groups@drive4ik.xpi".source =
          "${addons.simple-tab-groups}/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/simple-tab-groups@drive4ik.xpi";
        ".config/zen/${profileName}/extensions/{c2c003ee-bd69-42a2-b0e9-6f34222cb046}.xpi".source =
          "${addons.auto-tab-discard}/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/{c2c003ee-bd69-42a2-b0e9-6f34222cb046}.xpi";
        ".config/zen/${profileName}/extensions/webextension@metamask.io.xpi".source =
          "${addons.metamask}/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/webextension@metamask.io.xpi";
        ".config/zen/${profileName}/extensions/contaner-proxy@bekh-ivanov.me.xpi".source =
          "${addons.container-proxy}/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/contaner-proxy@bekh-ivanov.me.xpi";
        ".config/zen/${profileName}/extensions/keplr-extension@keplr.app.xpi".source =
          "${keplr}/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/keplr-extension@keplr.app.xpi";
        ".config/zen/${profileName}/extensions/{6d72262a-b243-4dc6-8f4f-be96c74e0a86}.xpi".source =
          "${solflare-wallet}/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/{6d72262a-b243-4dc6-8f4f-be96c74e0a86}.xpi";
      };
    };
}
