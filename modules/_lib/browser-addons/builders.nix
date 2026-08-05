# AMO addon build functions, Enterprise Policy extension settings, and addon resolver.
# Receives pre-computed data (amoAddons, geckoExtPath, firefoxAddons) from default.nix.
{
  lib,
  pkgs,
  firefoxAddons,
  amoAddons,
  geckoExtPath,
}:
let
  # Build a Firefox extension derivation fetched directly from Mozilla AMO
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

  # Generate ExtensionSettings for Enterprise Policies with direct AMO HTTPS URLs
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

  # Resolve addons from amoAddons to either firefox-addons packages or custom derivations
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
in
{
  inherit buildAmoAddon mkAmoExtensionSettings resolveAddons;
  mkExtensionSettings = mkAmoExtensionSettings; # alias for backwards compat
}
