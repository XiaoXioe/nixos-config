{
  config,
  lib,
  pkgs,
  selfLib,
  ...
}:

let
  cfg = config.my.user.brave;
in
{
  options.my.user.brave = {
    enable = selfLib.mkBoolOpt false "Brave browser configuration with maximal performance & privacy";
  };

  config = lib.mkIf cfg.enable {
    # === Cara Paling Reliable untuk Brave di NixOS ===
    home.packages = [
      (pkgs.brave.override {
        commandLineArgs = [
          # Performa & Hardware Acceleration (Intel HD 4000)
          "--enable-features=WaylandWindowDecorations,AcceleratedVideoDecodeLinuxGL,AcceleratedVideoDecodeLinuxZeroCopyGL,VaapiVideoDecoder,VaapiVideoEncoder,VaapiIgnoreDriverChecks"
          "--enable-gpu-rasterization"
          "--enable-zero-copy"
          "--ignore-gpu-blocklist"
          "--ozone-platform-hint=auto"
          "--enable-hardware-overlays"

          # Security & Hilangkan Bloat
          "--disable-domain-reliability"
          "--no-first-run"
          "--disable-breakpad"
          "--disable-features=BraveRewards,BraveWallet,BraveLeoAI,BraveSearchDefault,BraveNews,BraveReferrals"

          "--disable-background-networking"
        ];
      })
    ];
  };
}
