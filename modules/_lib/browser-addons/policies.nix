# Shared browser privacy policies, search engine config, and bookmark helpers.
# Used by Firefox, Zen, Tor Browser, and other Gecko-based browser modules.
_: {
  # Shared privacy/hardening policies applied across all Gecko browsers (Firefox, Zen, Tor)
  commonPrivacyPolicies = {
    DisableTelemetry = true;
    DisableCrashReporter = true;
    DisableFeedbackCommands = true;
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
}
