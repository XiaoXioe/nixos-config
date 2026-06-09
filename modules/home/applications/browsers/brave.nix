{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.user.apps.browser.brave;
in
{
  options.my.user.apps.browser.brave = {
    enable = lib.mkEnableOption "Brave browser configuration with maximal performance & privacy";
  };

  config = lib.mkIf cfg.enable {
    programs.brave = {
      enable = true;
      extensions = [
        { id = "pkehgijcmpdhfbdbbnkijodmdjhbjlgp"; } # Privacy Badger
        { id = "nngceckbapebfimnlniiiahkandclblb"; } # Bitwarden Password Manager
        { id = "jplgfhpmjnbigmhklmmbgecoobifkmpa"; } # Proton-vpn
        { id = "hlepfoohegkhhmjieoechaddaejaokhf"; } # Refined GitHub
        { id = "lptnjkfjeaemenlipfaaocppmilaeejf"; } # ClearURLs
        { id = "mnjggcdmjocbbbhaepdhchncahnbgone"; } # SponsorBlock
        { id = "jinjaccalgkegednnccohejagnlnfdag"; } # Violentmonkey
        { id = "omkfmpieigblcllmkgbflkikinpkodlk"; } # Enhanced-h264ify
        { id = "jhnleheckmknfcgijgkadoemagpecfol"; } # Auto Tab Discard (suspend)
        { id = "einpaelgookohagofgnnkcfjbkkgepnp"; } # Random User-Agent (Switcher)
        { id = "nplimhmoanghlebhdiboeellhgmgommi"; } # Tab Groups Extension
        { id = "cmpdlhmnmjhihmcfnigoememnffkimlk"; } # Catppuccin Macchiato
      ];
      commandLineArgs = [
        "--force-dark-mode" # Memaksa UI Brave menjadi gelap
        # --- Performa & Kompatibilitas Wayland ---
        "--ozone-platform=wayland"
        "--enable-wayland-ime"
        "--enable-gpu-rasterization" # Memaksa akselerasi GPU untuk rendering
        "--ignore-gpu-blocklist" # Memaksa fitur GPU meskipun driver tidak dikenali secara resmi

        # --- PAKSA HARDWARE DECODING (VA-API) ---
        "--enable-features=WebUIDarkMode,Containers,VaapiVideoDecoder,VaapiIgnoreDriverChecks"
        # "--enable-features=UseOzonePlatform,WebUIDarkMode,Containers,VaapiVideoDecoder,VaapiIgnoreDriverChecks,VaapiVideoEncoder"
        "--disable-features=Vulkan,UseChromeOSDirectVideoDecoder,BraveRewards,BraveWallet,BraveVPN,BraveLeo,BraveAI,WebDiscoveryProject"
        "--disable-gpu-driver-bug-workarounds" # Mengabaikan aturan pembatasan dari Chromium untuk GPU lama

        # --- Privasi Tambahan ---
        "--disable-reading-from-canvas" # Mencegah canvas fingerprinting
        "--no-pings" # Mencegah pengiriman hyperlink auditing pings
      ];
    };
  };
}
