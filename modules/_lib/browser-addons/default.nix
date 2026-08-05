# Shared Firefox/Zen/Tor Browser policy-lock helpers, privacy policies, search engines,
# and AMO addon builders (DRY: used by browser modules which are otherwise separate
# flatpak/native browser configs with no other common parent).
# Call with { inherit pkgs inputs; }.
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

  addonsData = import ./addons.nix;
  policies = import ./policies.nix { inherit lib; };
  builders = import ./builders.nix {
    inherit lib pkgs firefoxAddons;
    inherit (addonsData) amoAddons geckoExtPath;
  };
in
{
  # Firefox Enterprise Policy lock helpers
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

  inherit (addonsData)
    amoAddons
    commonChromiumExtensions
    geckoExtGuid
    geckoExtPath
    ;
  inherit (policies)
    commonPrivacyPolicies
    commonSearchEngines
    mkBookmarkPoliciesTemplate
    mkBookmarkSecret
    ;
  inherit (builders)
    buildAmoAddon
    mkAmoExtensionSettings
    mkExtensionSettings
    resolveAddons
    ;
}
