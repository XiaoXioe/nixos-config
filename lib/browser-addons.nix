# Shared Firefox/Zen/Tor Browser policy-lock helpers, privacy policies, search engines,
# and AMO addon builders (DRY: used by browser modules which are otherwise separate
# flatpak/native browser configs with no other common parent).
{
  pkgs,
  inputs ? { },
}:
let
  lib = pkgs.lib;
  addons =
    if inputs ? firefox-addons then
      inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system}
    else
      null;

  # Shared Chromium extension IDs across Brave, Chromium, etc.
  commonChromiumExtensions = [
    { id = "pkehgijcmpdhfbdbbnkijodmdjhbjlgp"; } # Privacy Badger
    { id = "nngceckbapebfimnlniiiahkandclblb"; } # Bitwarden Password Manager
    { id = "jplgfhpmjnbigmhklmmbgecoobifkmpa"; } # Proton-vpn
    { id = "hlepfoohegkhhmjieoechaddaejaokhf"; } # Refined GitHub
    { id = "lptnjkfjeaemenlipfaaocppmilaeejf"; } # ClearURLs
    { id = "mnjggcdmjocbbbhaepdhchncahnbgone"; } # SponsorBlock
    { id = "jinjaccalgkegednnccohejagnlnfdag"; } # Violentmonkey
    { id = "omkfmpieigblcllmkgbflkikinpkodlk"; } # Enhanced-h264ify
    { id = "jhnleheckmknfcgijgkadoemagpecfol"; } # Auto Tab Discard (suspend)
    { id = "cmpdlhmnmjhihmcfnigoememnffkimlk"; } # Catppuccin Macchiato
  ];

  # Canonical Gecko/Firefox extension directory GUID — single source of truth
  geckoExtGuid = "{ec8030f7-c20a-464f-9b0e-13a3a9e97384}";
  geckoExtPath = "/share/mozilla/extensions/${geckoExtGuid}";

  buildAmoAddon =
    {
      pname,
      addonId,
      sha256,
      slug ? pname,
      version ? "latest",
      url ? (
        if version == "latest" then
          "https://addons.mozilla.org/firefox/downloads/latest/${slug}/latest.xpi"
        else
          "https://addons.mozilla.org/firefox/downloads/file/${slug}/${version}/${slug}-${version}.xpi"
      ),
    }:
    pkgs.stdenv.mkDerivation {
      name = "${pname}-${version}";
      src = pkgs.fetchurl {
        inherit url sha256;
      };
      preferLocalBuild = true;
      allowSubstitutes = false;
      passthru = {
        inherit addonId;
      };
      buildCommand = ''
        dst="$out${geckoExtPath}"
        mkdir -p "$dst"
        ln -s "$src" "$dst/${addonId}.xpi"
      '';
    };

  mkExtensionSettings =
    extensionsList:
    {
      mode ? "allowed",
    }:
    let
      base = {
        "*" = {
          installation_mode = "blocked";
          blocked_install_message = "Ekstensi dikunci oleh sistem deklaratif NixOS. Tambahkan ekstensi baru di konfigurasi Nix Anda.";
        };
      };
      allowedAddons = lib.listToAttrs (
        lib.flatten (
          map (
            addon:
            let
              extId = addon.addonId or (addon.passthru.addonId or null);
            in
            if extId != null then
              [
                (lib.nameValuePair extId {
                  installation_mode = mode;
                  install_url = "file://${addon}${geckoExtPath}/${extId}.xpi";
                })
              ]
            else
              [ ]
          ) extensionsList
        )
      );
    in
    base // allowedAddons;

  # Shared privacy/hardening policies applied across all Gecko browsers (Firefox, Zen, Tor)
  commonPrivacyPolicies = {
    DisableTelemetry = true;
    SearchSuggestEnabled = false;
    DisableFirefoxStudies = true;
    PasswordManagerEnabled = false;
    DisableFirefoxAccounts = true;
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
  };

  # Shared custom search engine configuration for Firefox and Zen
  commonSearchEngines = {
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

  # Helper: generate sops.templates value for bookmark-injected policies.json
  mkBookmarkPoliciesTemplate =
    {
      ownerName,
      basePolicies,
      bookmarkPlaceholder,
    }:
    {
      owner = ownerName;
      mode = "0644";
      content = builtins.replaceStrings [ ''"__BOOKMARKS__"'' ] [ bookmarkPlaceholder ] (
        builtins.toJSON {
          policies = basePolicies // {
            Bookmarks = "__BOOKMARKS__";
          };
        }
      );
    };

  # Helper: generate sops.secrets value for binary bookmark files
  mkBookmarkSecret = sopsFile: {
    format = "binary";
    inherit sopsFile;
    mode = "0444";
  };
in
{
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

  inherit
    addons
    buildAmoAddon
    mkExtensionSettings
    commonPrivacyPolicies
    commonSearchEngines
    commonChromiumExtensions
    geckoExtPath
    mkBookmarkPoliciesTemplate
    mkBookmarkSecret
    ;

  proton-pass = buildAmoAddon {
    pname = "proton-pass";
    addonId = "78272b6fa58f4a1abaac99321d503a20@proton.me";
    sha256 = "1nzrxqk7iq5icjlb82h3qglr6k8gzha24hqm4rmpbdsi1cv9cnr2";
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

  tampermonkey =
    if addons != null && addons ? tampermonkey then
      addons.tampermonkey.overrideAttrs (
        _finalAttrs: old: {
          meta = (old.meta or { }) // {
            license = [ ];
          };
          passthru = (old.passthru or { }) // {
            addonId = old.addonId or "firefox@tampermonkey.net";
          };
        }
      )
    else
      buildAmoAddon {
        pname = "tampermonkey";
        addonId = "firefox@tampermonkey.net";
        sha256 = "1133333333333333333333333333333333333333333333333333"; # fallback if inputs not provided
      };
}
