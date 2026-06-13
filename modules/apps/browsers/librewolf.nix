{
  config,
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.browsers.librewolf";
  description = "LibreWolf configuration for user";

  hmConfig = {
    programs.librewolf = {
      enable = true;
      package = pkgs.librewolf;
      policies = {
        ExtensionSettings = {
          "*" = {
            installation_mode = "blocked";
            blocked_install_message = "Ekstensi harus dideklarasikan di librewolf.nix!";
          };
          "uBlock0@raymondhill.net" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
            installation_mode = "force_installed";
          };
          "@testpilot-containers" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/multi-account-containers/latest.xpi";
            installation_mode = "force_installed";
          };
          "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
            installation_mode = "force_installed";
          };
          "simple-tab-groups@drive4ik" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/simple-tab-groups/latest.xpi";
            installation_mode = "force_installed";
          };
          "vpn@proton.ch" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/proton-vpn-firefox-extension/latest.xpi";
            installation_mode = "force_installed";
          };
          "jid1-MnnxcxisBPnSXQ@jetpack" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/privacy-badger17/latest.xpi";
            installation_mode = "force_installed";
          };
          "wappalyzer@crunchlabz.com" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/wappalyzer/latest.xpi";
            installation_mode = "force_installed";
          };
          "CanvasBlocker@kkapsner.de" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/canvasblocker/latest.xpi";
            installation_mode = "force_installed";
          };
          "{74145f27-f039-47ce-a470-a662b129930a}" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/clearurls/latest.xpi";
            installation_mode = "force_installed";
          };
          "{b86e4813-687a-43e6-ab65-0bde4ab75758}" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/localcdn-fork-of-decentraleyes/latest.xpi";
            installation_mode = "force_installed";
          };
          "{a6c4a591-f1b2-4f03-b3ff-767e5bedf4e7}" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/user-agent-string-switcher/latest.xpi";
            installation_mode = "force_installed";
          };
        };
      };
      profiles.${config.my.user.name} = {
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
    home.file.".librewolf/${config.my.user.name}/chrome/userChrome.css".text = ''
      .tab-close-button { display: none !important; }
    '';
  };
}
