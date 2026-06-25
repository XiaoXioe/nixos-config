{
  pkgs,
  selfLib,
  userName,
  ...
}:
let
  mkExtension = shortId: uuid: extraAttrs: {
    name = uuid;
    value = {
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/${shortId}/latest.xpi";
      installation_mode = "force_installed";
    }
    // extraAttrs;
  };
in
selfLib.mkModule {
  name = "apps.browsers.librewolf";
  description = "LibreWolf configuration for user";

  hmConfig = hmOpts: {
    programs.librewolf = {
      enable = true;
      package = pkgs.librewolf;
      policies = {
        ExtensionSettings = {
          "*" = {
            installation_mode = "blocked";
            blocked_install_message = "Ekstensi harus dideklarasikan di librewolf.nix!";
          };
        }
        // builtins.listToAttrs [
          (mkExtension "ublock-origin" "uBlock0@raymondhill.net" { })
          (mkExtension "multi-account-containers" "@testpilot-containers" { })
          (mkExtension "bitwarden-password-manager" "{446900e4-71c2-419f-a6a7-df9c091e268b}" { })
          (mkExtension "simple-tab-groups" "simple-tab-groups@drive4ik" { })
          (mkExtension "proton-vpn-firefox-extension" "vpn@proton.ch" { })
          (mkExtension "privacy-badger17" "jid1-MnnxcxisBPnSXQ@jetpack" { })
          (mkExtension "wappalyzer" "wappalyzer@crunchlabz.com" { })
          (mkExtension "canvasblocker" "CanvasBlocker@kkapsner.de" { })
          (mkExtension "clearurls" "{74145f27-f039-47ce-a470-a662b129930a}" { })
          (mkExtension "localcdn-fork-of-decentraleyes" "{b86e4813-687a-43e6-ab65-0bde4ab75758}" { })
          (mkExtension "user-agent-string-switcher" "{a6c4a591-f1b2-4f03-b3ff-767e5bedf4e7}" { })
        ];
      };
      profiles.${userName} = {
        isDefault = true;
        bookmarks = {
          force = true;
          settings = [
            {
              name = "Github Trending";
              url = "https://trendshift.io/";
            }
            {
              name = "Convert curl commands to Python, JavaScript and more";
              url = "https://curlconverter.com/";
            }
            {
              name = "The Cyber Swiss Army Knife";
              url = "https://gchq.github.io/CyberChef/";
            }
          ];
        };
      };
      settings = {
        "sidebar.verticalTabs" = true;
        "sidebar.revamp" = true;
        "general.autoScroll" = true;
        "widget.use-xdg-desktop-portal.file-picker" = 1;
        "browser.startup.page" = 3;
        "browser.tabs.inTitlebar" = 0;
        "xpinstall.signatures.required" = false;
        "extensions.webextensions.restrictedDomains" = "";
        "privacy.resistFingerprinting" = true;
        "dom.security.https_only_mode" = true;
        "browser.send_pings" = false;
        "network.dns.disablePrefetch" = true;
        "signon.rememberSignons" = false;
      };
    };
    home.file.".librewolf/${userName}/chrome/userChrome.css".text = ''
      .tab-close-button { display: none !important; }
    '';
  };
}
