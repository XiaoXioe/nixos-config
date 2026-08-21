{ lib }:

let
  common = import ../common.nix;
in
{
  # ── Identity ────────────────────────────────────────────────────────────────
  name = "void";
  detectionPatterns = [ "void" ];

  # ── Package manager ─────────────────────────────────────────────────────────
  pkgManager = "xbps";
  checkCmd = "xbps-install";
  installCmd = "xbps-install -Sy";

  # ── Base GUI / font / audio packages ────────────────────────────────────────
  basePackages = _: [
    "ca-certificates"
    "curl"
    "gnupg"
    "dejavu-fonts"
    "noto-fonts-emoji"
    "font-liberation-ttf"
    "MesaLib"
    "vulkan-loader"
    "pipewire"
    "libpulseaudio"
    "alsa-lib"
  ];

  # ── Pre-init hooks ──────────────────────────────────────────────────────────
  preInitHooks = [
    common.systemdMountHook
  ];
}
