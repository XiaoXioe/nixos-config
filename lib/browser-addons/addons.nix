# AMO addon registry, Chromium extension IDs, and Gecko path constants.
# Pure data — no pkgs or lib required; import directly without arguments.
let
  # Canonical Gecko/Firefox extension directory GUID — single source of truth
  geckoExtGuid = "{ec8030f7-c20a-464f-9b0e-13a3a9e97384}";
in
{
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

  inherit geckoExtGuid;
  geckoExtPath = "/share/mozilla/extensions/${geckoExtGuid}";
}
