{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.user.brave;
in
{
  options.my.user.brave = {
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
      ];
      commandLineArgs = [
        "--force-dark-mode" # Memaksa UI Brave menjadi gelap
        "--enable-features=WebUIDarkMode" # Memaksa halaman internal (seperti Pengaturan) menjadi gelap
        # --- Performa & Kompatibilitas Wayland ---
        "--enable-features=UseOzonePlatform"
        "--ozone-platform=wayland" # Aktifkan jika Anda memakai Wayland (Hyprland, Sway, GNOME Wayland)
        "--enable-gpu-rasterization" # Memaksa akselerasi GPU untuk rendering
        "--enable-zero-copy" # Mengurangi penggunaan RAM saat rendering
        "--ignore-gpu-blocklist" # Memaksa fitur GPU meskipun driver tidak dikenali secara resmi
        "--disable-features=BraveRewards,BraveWallet,BraveVPN,BraveLeo,BraveAI,WebDiscoveryProject"

        # --- Privasi Tambahan ---
        "--disable-reading-from-canvas" # Mencegah canvas fingerprinting
        "--no-pings" # Mencegah pengiriman hyperlink auditing pings
      ];
    };
  };
}
