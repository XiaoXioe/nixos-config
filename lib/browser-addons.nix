# Shared Firefox/Zen policy-lock helpers and AMO addon builders (DRY: used by
# ../firefox/default.nix and ./zen/default.nix, which are otherwise separate
# flatpak/native browser configs with no other common parent).
{ pkgs, inputs }:
let
  addons = inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system};

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
        dst="$out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}"
        mkdir -p "$dst"
        ln -s "$src" "$dst/${addonId}.xpi"
      '';
    };

  mkExtensionSettings =
    extensionsList:
    let
      base = {
        "*" = {
          installation_mode = "blocked";
          blocked_install_message = "Ekstensi dikunci oleh sistem deklaratif NixOS. Tambahkan ekstensi baru di konfigurasi Nix Anda.";
        };
      };
      allowedAddons = pkgs.lib.listToAttrs (
        pkgs.lib.flatten (
          map (
            addon:
            let
              extId = addon.addonId or (addon.passthru.addonId or null);
            in
            if extId != null then
              [
                (pkgs.lib.nameValuePair extId {
                  installation_mode = "allowed";
                })
              ]
            else
              [ ]
          ) extensionsList
        )
      );
    in
    base // allowedAddons;
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

  inherit addons buildAmoAddon mkExtensionSettings;

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
    passthru = (old.passthru or { }) // {
      addonId = old.addonId or "firefox@tampermonkey.net";
    };
  });
}
