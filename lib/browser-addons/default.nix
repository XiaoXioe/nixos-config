# Shared Firefox/Zen/Tor Browser policy-lock helpers, privacy policies, search engines,
# and AMO addon builders (DRY: used by browser modules which are otherwise separate
# flatpak/native browser configs with no other common parent).
{
  pkgs,
  inputs ? { },
}:
let
  lib = pkgs.lib;

  firefoxAddons =
    if inputs ? firefox-addons then
      inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system}
    else
      { };

  # Remote AMO extension definitions (addonId + Mozilla AMO slug) for direct policy auto-update
  amoAddons = {
    ghost-downloader = {
      addonId = "ghostdownloader@github.com";
      slug = "ghost-downloader";
      sha256 = "086jajf31973pdb9rc4s0jf6kyis4l1iy5m2rfc2d6jhzb7lcgcn";
    };
    remove-youtube-tracking = {
      addonId = "remove.youtube.tracking@moreo.app";
      slug = "remove-youtube-tracking";
      sha256 = "01lf497z5vh9fw5mbikc1n1m352f6k6gf9d32g9p0sjb3anpycw7";
    };
    gh-repo-size = {
      addonId = "github-repository-size@pranavmangal";
      slug = "gh-repo-size";
      sha256 = "03markdbwl3x38r3pjp6rxiifxkbb9kjvmq2jl8kiay0alk8gcja";
    };
    ublock-origin = {
      addonId = "uBlock0@raymondhill.net";
      slug = "ublock-origin";
    };
    bitwarden = {
      addonId = "{446900e4-71c2-419f-a6a7-df9c091e268b}";
      slug = "bitwarden-password-manager";
      pkgName = "bitwarden";
    };
    multi-account-containers = {
      addonId = "@testpilot-containers";
      slug = "multi-account-containers";
    };
    auto-tab-discard = {
      addonId = "{c2c003ee-bd69-42a2-b0e9-6f34222cb046}";
      slug = "auto-tab-discard";
    };
    proton-pass = {
      addonId = "78272b6fa58f4a1abaac99321d503a20@proton.me";
      slug = "proton-pass";
    };
    tampermonkey = {
      addonId = "firefox@tampermonkey.net";
      slug = "tampermonkey";
      sha256 = "022r0s61bz7qg3r5vprlw78mm1bbiqn1yq1m908rcmmwip3k200r";
    };
    keplr = {
      addonId = "keplr-extension@keplr.app";
      slug = "keplr";
      sha256 = "166ggld6b4lh1hvsm2bd0g8b7kp7y9ln2fhf7jfcmx0pbd9z4zzp";
    };
    solflare-wallet = {
      addonId = "{6d72262a-b243-4dc6-8f4f-be96c74e0a86}";
      slug = "solflare-wallet";
      sha256 = "08410liim0kx5cdd323dbv8fsnb39hi13njnp5dallarphwhx3gg";
    };
    simple-tab-groups = {
      addonId = "Drive4ik@SimpleTabGroups";
      slug = "simple-tab-groups";
    };
    metamask = {
      addonId = "webextension@metamask.io";
      slug = "ether-metamask";
      pkgName = "metamask";
    };
    container-proxy = {
      addonId = "{c0e86b03-53d9-482a-995b-b9dcb99c855a}";
      slug = "container-proxy";
    };
    privacy-badger = {
      addonId = "jwz@eff.org";
      slug = "privacy-badger17";
      pkgName = "privacy-badger";
    };
    canvasblocker = {
      addonId = "CanvasBlocker@kkapsner.de";
      slug = "canvasblocker";
    };
    localcdn = {
      addonId = "{344c37a9-8f90-4eac-a5c1-48ad705148f4}";
      slug = "localcdn-fork-of-decentraleyes";
      pkgName = "localcdn";
    };
    user-agent-string-switcher = {
      addonId = "{72004245-c408-410a-9d93-3d0781745484}";
      slug = "user-agent-string-switcher";
    };
    proton-vpn = {
      addonId = "vpn@proton.me";
      slug = "proton-vpn-firefox-extension";
      pkgName = "proton-vpn";
    };
  };

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

  # Helper to generate ExtensionSettings for Enterprise Policies with direct HTTPS Mozilla AMO URLs
  mkAmoExtensionSettings =
    extensionsList:
    {
      mode ? "force_installed",
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
              extSlug = addon.slug or (addon.pname or null);
            in
            if extId != null && extSlug != null then
              [
                (lib.nameValuePair extId {
                  installation_mode = mode;
                  install_url = "https://addons.mozilla.org/firefox/downloads/latest/${extSlug}/latest.xpi";
                })
              ]
            else
              [ ]
          ) extensionsList
        )
      );
    in
    base // allowedAddons;

  mkExtensionSettings = mkAmoExtensionSettings;

  # Helper to resolve addons from amoAddons to either firefox-addons packages or custom derivations
  resolveAddons =
    addonsList:
    map (
      addon:
      if addon ? sha256 then
        buildAmoAddon {
          pname = addon.pkgName or addon.slug;
          addonId = addon.addonId;
          sha256 = addon.sha256;
          slug = addon.slug;
        }
      else
        firefoxAddons.${addon.pkgName or addon.slug}
          or (throw "Addon ${addon.pkgName or addon.slug} not found in firefox-addons")
    ) addonsList;

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
    amoAddons
    buildAmoAddon
    mkAmoExtensionSettings
    mkExtensionSettings
    resolveAddons
    commonPrivacyPolicies
    commonSearchEngines
    commonChromiumExtensions
    geckoExtPath
    mkBookmarkPoliciesTemplate
    mkBookmarkSecret
    ;
}
