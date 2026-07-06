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

  inherit addons buildAmoAddon;

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
}
